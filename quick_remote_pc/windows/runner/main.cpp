#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <algorithm>

#include "flutter_window.h"
#include "utils.h"

namespace {

// The window title window_manager gives the app (lib/main.dart); the runner
// creates the window with it too, so a second copy finds it from the start.
constexpr const wchar_t kWindowTitle[] = L"QuickRemote PC";

// Brings the running copy's window forward, also when it is hidden in the
// tray. The copy the user just started may set the foreground window.
void ActivateRunningCopy() {
  HWND window = ::FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", kWindowTitle);
  if (window == nullptr) return;
  ::ShowWindow(window, ::IsIconic(window) ? SW_RESTORE : SW_SHOW);
  ::SetForegroundWindow(window);
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // One copy at a time: a second one would try to open the same port. The
  // mutex lives until this process exits.
  HANDLE single_instance =
      ::CreateMutexW(nullptr, TRUE, L"Local\\QuickRemotePC");
  if (single_instance != nullptr && ::GetLastError() == ERROR_ALREADY_EXISTS) {
    ActivateRunningCopy();
    ::CloseHandle(single_instance);
    return EXIT_SUCCESS;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  // Started at login (the Run key): the window stays hidden, in the tray.
  const bool start_hidden =
      std::find(command_line_arguments.begin(), command_line_arguments.end(),
                "--minimized") != command_line_arguments.end();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  window.set_start_hidden(start_hidden);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(kWindowTitle, origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
