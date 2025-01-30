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

#include "flutter/generated_plugin_registrant.h"

std::mutex g_appListMutex;
std::unordered_set<std::string> g_appList;
bool g_allowList = false;

// Timer ID for the window check
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

// Timer callback for checking active window
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
                    logMessage << L"\nProcess Path: " << processPath;

                    // Convert process path to lowercase string for comparison
                    std::wstring wProcessPath(processPath);
                    size_t lastBackslash = wProcessPath.find_last_of(L"\\");
                    std::wstring exeName = wProcessPath.substr(lastBackslash + 1);
                    
                    // Convert exe name to lowercase before removing extension
                    std::transform(exeName.begin(), exeName.end(), exeName.begin(), ::towlower);
                    
                    size_t lastDot = exeName.find_last_of(L".");
                    if (lastDot != std::wstring::npos) {
                        exeName = exeName.substr(0, lastDot);
                    }

                    // Convert wide string to narrow string using Windows API
                    int narrowSize = WideCharToMultiByte(CP_UTF8, 0, exeName.c_str(), -1, nullptr, 0, nullptr, nullptr);
                    std::string narrowExeName(narrowSize, 0);
                    WideCharToMultiByte(CP_UTF8, 0, exeName.c_str(), -1, &narrowExeName[0], narrowSize, nullptr, nullptr);
                    narrowExeName.pop_back(); // Remove the null terminator
                    
                    // Convert to lowercase using explicit cast to avoid warning
                    std::transform(narrowExeName.begin(), narrowExeName.end(), 
                                 narrowExeName.begin(), 
                                 [](unsigned char c) -> char { return static_cast<char>(std::tolower(static_cast<unsigned char>(c))); });
                    
                    logMessage << L"\nExecutable Name: " << exeName.c_str();

                    std::lock_guard lock{ g_appListMutex };
                    // Check if app should be blocked
                    bool inList = g_appList.find(narrowExeName) != g_appList.end();

                    if ((g_allowList && !inList) || (!g_allowList && inList)) {
                        logMessage << L"\nBlocking application: " << exeName.c_str();
                        
                        // Disable the window to prevent interaction
                        EnableWindow(foregroundWindow, FALSE);
                        
                        // Also minimize it to reduce visibility
                        ShowWindow(foregroundWindow, SW_MINIMIZE);
                        
                        // Small delay to let the window respond
                        Sleep(100);
                        
                        // Check if window is not minimized and try again
                        WINDOWPLACEMENT placement = { sizeof(WINDOWPLACEMENT) };
                        if (GetWindowPlacement(foregroundWindow, &placement) && 
                            placement.showCmd != SW_SHOWMINIMIZED) {
                            ShowWindow(foregroundWindow, SW_MINIMIZE);
                            EnableWindow(foregroundWindow, FALSE);  // Ensure it stays disabled
                        }
                    }

                    LogToFile(logMessage.str());
                }
                CloseHandle(hProcess);
            }
        }
    }
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
          std::lock_guard lock{ g_appListMutex };

          if (methodType == "engineReady") {
              LogToFile(L"Received engineReady");
              result->Success(true);
          }
          else if (methodType == "updateAppList") {
              LogToFile(L"Received updateAppList");
             
              if (const auto* arguments = std::get_if<flutter::EncodableMap>(call.arguments())) {
                  auto list_it = arguments->find(flutter::EncodableValue("apps"));
                  auto allow_it = arguments->find(flutter::EncodableValue("allowList"));

                  if (list_it != arguments->end() && allow_it != arguments->end()) {
                      const auto& list = std::get<flutter::EncodableList>(list_it->second);
                      std::vector<std::string> apps;
                      for (const auto& item : list) {
                          if (std::holds_alternative<std::string>(item)) {
                              apps.push_back(std::get<std::string>(item));
                          }
                      }
                      g_appList = std::unordered_set<std::string>{ apps.begin(), apps.end() };
                      g_allowList = std::get<bool>(allow_it->second);

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
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
