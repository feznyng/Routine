#include "flutter_window.h"
#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <debugapi.h>
#include <fstream>
#include <ctime>
#include <sstream>
#include <algorithm>
#include <string>
#include <memory>
#include <optional>
#include <TlHelp32.h>
#include <psapi.h>

// Add pragma comment to link with version.lib
#pragma comment(lib, "version.lib")

#include "flutter/generated_plugin_registrant.h"

#include "block_manager.h"

const UINT_PTR WINDOW_CHECK_TIMER_ID = 1;

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

void LogToFile(const std::wstring& message) {
    static std::wofstream logFile;
    if (!logFile.is_open()) {
        logFile.open("routine_app.log", std::ios::app);
    }
    
    logFile << message << std::endl;
}

void CALLBACK CheckActiveWindow(HWND hwnd, UINT message, UINT_PTR idTimer, DWORD dwTime) {
    HWND foregroundWindow = GetForegroundWindow();
    if (foregroundWindow != NULL) {
        std::wstringstream logMessage;
        
        DWORD processId;
        GetWindowThreadProcessId(foregroundWindow, &processId);
        if (processId != 0) {
            HANDLE hProcess = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, processId);
            if (hProcess != NULL) {
                wchar_t processPath[MAX_PATH];
                DWORD size = MAX_PATH;
                if (QueryFullProcessImageNameW(hProcess, 0, processPath, &size)) {
                    const std::wstring processPathW{ processPath };
                    logMessage << L"\nFocused application: " << processPath;

                    if (BlockManager::IsBlocked(processPathW)) {
                        logMessage << L"\nBlocking application: " << processPath;
                        ShowWindow(foregroundWindow, SW_MINIMIZE);
                    }

                    LogToFile(logMessage.str());
                }
                CloseHandle(hProcess);
            }
        }
    }
}

std::vector<std::string> ConvertFlutterListToVector(const std::vector<flutter::EncodableValue>& list) {
    std::vector<std::string> items;
    for (const auto& item : list) {
        if (const auto* str = std::get_if<std::string>(&item)) {
            items.push_back(*str);
        }
    }
    return items;
}

// Helper function to get file version info string
std::string GetFileVersionInfoString(const wchar_t* filePath, const wchar_t* stringName) {
    DWORD handle;
    DWORD size = GetFileVersionInfoSizeW(filePath, &handle);
    if (size == 0) {
        return "";
    }

    std::vector<BYTE> data(size);
    if (!GetFileVersionInfoW(filePath, handle, size, data.data())) {
        return "";
    }

    struct LANGANDCODEPAGE {
        WORD language;
        WORD codePage;
    } *translations;
    
    UINT translationsLength;
    if (!VerQueryValueW(data.data(), L"\\VarFileInfo\\Translation", (LPVOID*)&translations, &translationsLength)) {
        return "";
    }

    // Try to get the string for each language/codepage
    for (UINT i = 0; i < translationsLength / sizeof(LANGANDCODEPAGE); i++) {
        wchar_t subBlock[128];
        swprintf_s(subBlock, L"\\StringFileInfo\\%04x%04x\\%s", 
            translations[i].language, translations[i].codePage, stringName);
        
        LPVOID valuePtr;
        UINT valueLength;
        if (VerQueryValueW(data.data(), subBlock, &valuePtr, &valueLength) && valueLength > 0) {
            // Convert wide string to UTF-8
            int bufferSize = WideCharToMultiByte(CP_UTF8, 0, (wchar_t*)valuePtr, -1, nullptr, 0, nullptr, nullptr);
            if (bufferSize > 0) {
                std::string result(bufferSize, 0);
                WideCharToMultiByte(CP_UTF8, 0, (wchar_t*)valuePtr, -1, &result[0], bufferSize, nullptr, nullptr);
                result.resize(bufferSize - 1);  // Remove null terminator
                return result;
            }
        }
    }

    return "";
}

// Helper function to check if a process has a visible window
bool HasVisibleWindow(DWORD processId) {
    struct WindowInfo {
        DWORD processId;
        bool hasVisibleWindow;
    };
    
    WindowInfo info = {processId, false};
    
    // Enumerate all top-level windows and check if any belong to our process
    EnumWindows([](HWND hwnd, LPARAM lParam) -> BOOL {
        WindowInfo* info = reinterpret_cast<WindowInfo*>(lParam);
        
        // Skip invisible windows
        if (!IsWindowVisible(hwnd)) {
            return TRUE; // Continue enumeration
        }
        
        // Check if this window belongs to our process
        DWORD windowProcessId;
        GetWindowThreadProcessId(hwnd, &windowProcessId);
        
        if (windowProcessId == info->processId) {
            // Check if it's a real application window (not a tool window)
            LONG style = GetWindowLong(hwnd, GWL_EXSTYLE);
            if (!(style & WS_EX_TOOLWINDOW)) {
                // Get window title to further filter out non-application windows
                char title[256];
                if (GetWindowTextA(hwnd, title, sizeof(title)) > 0) {
                    info->hasVisibleWindow = true;
                    return FALSE; // Stop enumeration, we found a window
                }
            }
        }
        
        return TRUE; // Continue enumeration
    }, reinterpret_cast<LPARAM>(&info));
    
    return info.hasVisibleWindow;
}

flutter::EncodableList GetRunningApplications() {
    flutter::EncodableList result;
    
    // Create a snapshot of all processes
    HANDLE hProcessSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (hProcessSnap == INVALID_HANDLE_VALUE) {
        return result;
    }
    
    PROCESSENTRY32 pe32;
    pe32.dwSize = sizeof(PROCESSENTRY32);
    
    // Get the first process
    if (!Process32First(hProcessSnap, &pe32)) {
        CloseHandle(hProcessSnap);
        return result;
    }
    
    // Iterate through all processes
    do {
        // Skip system processes
        if (pe32.th32ProcessID == 0 || pe32.th32ProcessID == 4) {
            continue;
        }
        
        // Check if the process has a visible window
        if (!HasVisibleWindow(pe32.th32ProcessID)) {
            continue; // Skip background processes
        }
        
        HANDLE hProcess = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pe32.th32ProcessID);
        if (hProcess != NULL) {
            wchar_t processPath[MAX_PATH];
            DWORD size = MAX_PATH;
            
            if (QueryFullProcessImageNameW(hProcess, 0, processPath, &size)) {
                // Convert wide string to UTF-8 string properly
                int bufferSize = WideCharToMultiByte(CP_UTF8, 0, processPath, -1, nullptr, 0, nullptr, nullptr);
                if (bufferSize > 0) {
                    std::string processPathStr(bufferSize, 0);
                    WideCharToMultiByte(CP_UTF8, 0, processPath, -1, &processPathStr[0], bufferSize, nullptr, nullptr);
                    // Remove null terminator that WideCharToMultiByte includes
                    processPathStr.resize(bufferSize - 1);
                    
                    // Extract the file name from the path
                    std::string fileName = processPathStr;
                    size_t lastSlash = fileName.find_last_of("\\");
                    if (lastSlash != std::string::npos) {
                        fileName = fileName.substr(lastSlash + 1);
                    }
                    
                    // Remove .exe extension if present
                    size_t dotPos = fileName.find_last_of(".");
                    if (dotPos != std::string::npos) {
                        fileName = fileName.substr(0, dotPos);
                    }
                    
                    // Try to get the display name from version info
                    std::string displayName = GetFileVersionInfoString(processPath, L"ProductName");
                    if (displayName.empty()) {
                        // Try FileDescription if ProductName is not available
                        displayName = GetFileVersionInfoString(processPath, L"FileDescription");
                    }
                    
                    // If we still don't have a display name, use the file name
                    if (displayName.empty()) {
                        displayName = fileName;
                    }
                    
                    // Create a map with name, display name, and path
                    flutter::EncodableMap appInfo;
                    appInfo[flutter::EncodableValue("name")] = flutter::EncodableValue(fileName);
                    appInfo[flutter::EncodableValue("displayName")] = flutter::EncodableValue(displayName);
                    appInfo[flutter::EncodableValue("path")] = flutter::EncodableValue(processPathStr);
                    
                    // Add to result list
                    result.push_back(flutter::EncodableValue(appInfo));
                }
            }
            
            CloseHandle(hProcess);
        }
    } while (Process32Next(hProcessSnap, &pe32));
    
    CloseHandle(hProcessSnap);
    return result;
}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  } 

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  flutter::MethodChannel<> channel(
      flutter_controller_->engine()->messenger(), "com.routine.applist",
      &flutter::StandardMethodCodec::GetInstance());
  channel.SetMethodCallHandler(
      [](const flutter::MethodCall<>& call, std::unique_ptr<flutter::MethodResult<>> result) {
          const auto& methodType = call.method_name();

          if (methodType == "engineReady") {
              LogToFile(L"Received engineReady");
              result->Success(true);
          }
          else if (methodType == "updateAppList") {
              LogToFile(L"Received updateAppList");
             
              if (const auto* arguments = std::get_if<flutter::EncodableMap>(call.arguments())) {
                    auto itAppList = arguments->find(flutter::EncodableValue("apps"));
                    auto itDirList = arguments->find(flutter::EncodableValue("categories"));
                    auto itAllow = arguments->find(flutter::EncodableValue("allowList"));

                    if (itAppList != arguments->end() && itAllow != arguments->end() && itDirList != arguments->end()) {

                        bool allow = std::get<bool>(itAllow->second);
                        std::vector<std::string> appList = ConvertFlutterListToVector(std::get<flutter::EncodableList>(itAppList->second));
                        std::vector<std::string> dirList = ConvertFlutterListToVector(std::get<flutter::EncodableList>(itDirList->second));
          
                        BlockManager::Set(allow, appList, dirList);
                        return result->Success(true);
                    }
              }
              
              result->Error("Arguments for updateAppList are invalid");
          }
          else if (methodType == "setStartOnLogin") {
              LogToFile(L"Received setStartOnLogin");
              result->Success(true);
          }
          else if (methodType == "getStartOnLogin") {
              LogToFile(L"Received getStartOnLogin");
              result->Success(false);
          }
          else if (methodType == "getRunningApplications") {
              LogToFile(L"Received getRunningApplications");
              result->Success(GetRunningApplications());
          }
      });


  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // Set up the timer to check active window every 200ms
  SetTimer(GetHandle(), WINDOW_CHECK_TIMER_ID, 200, CheckActiveWindow);

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
    // Kill the timer when the window is destroyed
    KillTimer(GetHandle(), WINDOW_CHECK_TIMER_ID);

    if (flutter_controller_) {
        flutter_controller_ = nullptr;
    }

    Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_CLOSE:
      // Instead of closing, minimize to system tray
      ShowWindow(hwnd, SW_MINIMIZE);
      return 0;  // Prevent default handling
      
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
      
    case WM_POWERBROADCAST:
      if (wparam == PBT_APMRESUMEAUTOMATIC || wparam == PBT_APMRESUMESUSPEND) {
        // System is waking up from sleep or hibernation
        LogToFile(L"[Routine] System wake event detected in Windows");
        
        // Get current timestamp for logging
        time_t now = time(0);
        tm localTime;
        char timestamp[64];
        localtime_s(&localTime, &now);
        strftime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S", &localTime);
        
        std::wstringstream wss;
        wss << L"[Routine] System wake at: " << timestamp;
        LogToFile(wss.str());
        
        // Create arguments with timestamp
        flutter::EncodableMap arguments;
        arguments[flutter::EncodableValue("timestamp")] = flutter::EncodableValue(timestamp);
        
        // Notify Flutter that the system woke from sleep
        if (flutter_controller_ && flutter_controller_->engine()) {
          LogToFile(L"[Routine] Sending systemWake event to Flutter");
          flutter::MethodChannel<> channel(
              flutter_controller_->engine()->messenger(), "com.routine.applist",
              &flutter::StandardMethodCodec::GetInstance());
          channel.InvokeMethod("systemWake", std::make_unique<flutter::EncodableValue>(arguments));
        } else {
          LogToFile(L"[Routine] Flutter controller not ready, cannot send systemWake event");
        }
      }
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
