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
