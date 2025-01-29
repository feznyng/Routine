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

#include <memory>
#include <optional>

#include "flutter/generated_plugin_registrant.h"

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

// WinEventProc callback implementation
void CALLBACK FlutterWindow::WinEventProc(HWINEVENTHOOK hWinEventHook, DWORD event,
    HWND hwnd, LONG idObject, LONG idChild,
    DWORD idEventThread, DWORD dwmsEventTime) {
    
    if (event == EVENT_SYSTEM_FOREGROUND && hwnd != NULL) {
        wchar_t windowTitle[256];
        if (GetWindowTextW(hwnd, windowTitle, 256) > 0) {
            std::wstringstream logMessage;
            logMessage << L"Window Focused - Title: " << windowTitle;
            
            // Get process information
            DWORD processId;
            GetWindowThreadProcessId(hwnd, &processId);
            if (processId != 0) {
                HANDLE hProcess = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, processId);
                if (hProcess != NULL) {
                    wchar_t processPath[MAX_PATH];
                    DWORD size = MAX_PATH;
                    if (QueryFullProcessImageNameW(hProcess, 0, processPath, &size)) {
                        logMessage << L"\nProcess Path: " << processPath;
                    }
                    CloseHandle(hProcess);
                }
            }
            
            LogToFile(logMessage.str());
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
      [this](const flutter::MethodCall<>& call, std::unique_ptr<flutter::MethodResult<>> result) {
          const auto& methodType = call.method_name();
          std::lock_guard lock{ this->appListMutex };

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
                      this->appList = std::unordered_set<std::string>{ apps.begin(), apps.end() };
                      this->allowList = std::get<bool>(allow_it->second);

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

  // Set up window focus tracking
  winEventHook = SetWinEventHook(
      EVENT_SYSTEM_FOREGROUND, EVENT_SYSTEM_FOREGROUND,
      NULL,
      WinEventProc,
      0, 0,
      WINEVENT_OUTOFCONTEXT | WINEVENT_SKIPOWNPROCESS
  );

  if (winEventHook == NULL) {
      LogToFile(L"Failed to set up window focus tracking");
  } else {
      LogToFile(L"Successfully set up window focus tracking");
  }

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
  if (winEventHook != nullptr) {
    UnhookWinEvent(winEventHook);
    winEventHook = nullptr;
    LogToFile(L"Window focus tracking stopped");
  }

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
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
