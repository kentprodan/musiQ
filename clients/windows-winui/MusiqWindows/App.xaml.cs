using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Data;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Navigation;

// To learn more about WinUI, the WinUI project structure,
// and more about our project templates, see: http://aka.ms/winui-project-info.

namespace MusiqWindows;

/// <summary>
/// Provides application-specific behavior to supplement the default Application class.
/// </summary>
public partial class App : Application
{
    private Window? _window;

    /// <summary>
    /// The app's single top-level window, exposed so pages can get an HWND
    /// (via <c>WinRT.Interop.WindowNative</c>) for WinRT APIs that need one,
    /// such as <see cref="Windows.Storage.Pickers.FolderPicker"/>.
    /// </summary>
    public static Window? MainAppWindow { get; private set; }

    /// <summary>
    /// Initializes the singleton application object.  This is the first line of authored code
    /// executed, and as such is the logical equivalent of main() or WinMain().
    /// </summary>
    public App()
    {
        InitializeComponent();
        UnhandledException += App_UnhandledException;
    }

    /// <summary>
    /// Invoked when the application is launched.
    /// </summary>
    /// <param name="args">Details about the launch request and process.</param>
    protected override void OnLaunched(Microsoft.UI.Xaml.LaunchActivatedEventArgs args)
    {
        _window = new MainWindow();
        MainAppWindow = _window;
        _window.Activate();
    }

    private void App_UnhandledException(object sender, Microsoft.UI.Xaml.UnhandledExceptionEventArgs e)
    {
        try
        {
            var logPath = System.IO.Path.Combine(
                Windows.Storage.ApplicationData.Current.LocalFolder.Path,
                "crash.log");
            System.IO.File.WriteAllText(logPath, $"{DateTime.Now:O}\n{e.Exception}\n");
        }
        catch
        {
            // Best-effort diagnostic logging only — never let logging itself throw during a crash.
        }
    }
}
