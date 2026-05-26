#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // One POS window per user session — extra clicks focus the running app instead
  // of starting a second process that blocks on the SQLite file.
  HANDLE single_instance_mutex = ::CreateMutexW(
      nullptr, TRUE, L"Global\\ZaadPOS_SingleInstance_v1");
  if (single_instance_mutex != nullptr &&
      ::GetLastError() == ERROR_ALREADY_EXISTS) {
    if (ActivateExistingPosWindow()) {
      return EXIT_SUCCESS;
    }
    // Stuck pos.exe after a bad sync: mutex exists but no window. Do not exit
    // silently (shortcut looks broken). Start a new instance so the user gets a
    // window; Dart startup will surface DB-lock errors if the zombie still holds
    // the database.
    if (single_instance_mutex != nullptr) {
      ::CloseHandle(single_instance_mutex);
      single_instance_mutex = nullptr;
    }
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

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"pos", origin, size)) {
    ::MessageBoxW(
        nullptr,
        L"Zaad POS could not create its window.\n\n"
        L"Try reinstalling the app or run it from the folder where pos.exe was "
        L"built (Release\\pos.exe with the data folder beside it).",
        L"Zaad POS",
        MB_OK | MB_ICONERROR);
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
