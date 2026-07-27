using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using MusiqWindows.Pages;

// To learn more about WinUI, the WinUI project structure,
// and more about our project templates, see: http://aka.ms/winui-project-info.

namespace MusiqWindows;

public sealed partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();

        ExtendsContentIntoTitleBar = true;
        SetTitleBar(AppTitleBar);
        AppWindow.TitleBar.PreferredHeightOption = TitleBarHeightOption.Tall;
        AppWindow.SetIcon("Assets/AppIcon.ico");

        // NavigationView.IsSelected on the initial item doesn't raise SelectionChanged,
        // so the Frame needs an explicit first navigation or it starts empty.
        NavFrame.Navigate(typeof(LibraryPage));
    }

    private void TitleBar_PaneToggleRequested(TitleBar sender, object args)
    {
        NavView.IsPaneOpen = !NavView.IsPaneOpen;
    }

    private void TitleBar_BackRequested(TitleBar sender, object args)
    {
        NavFrame.GoBack();
    }

    private void NavView_SelectionChanged(NavigationView sender, NavigationViewSelectionChangedEventArgs args)
    {
        if (args.IsSettingsSelected)
        {
            NavFrame.Navigate(typeof(SettingsPage));
        }
        else if (args.SelectedItem is NavigationViewItem item)
        {
            switch (item.Tag)
            {
                case "library":
                    NavFrame.Navigate(typeof(LibraryPage));
                    break;
                case "nowplaying":
                    NavFrame.Navigate(typeof(NowPlayingPage));
                    break;
                case "sources":
                    NavFrame.Navigate(typeof(SourcesPage));
                    break;
                default:
                    throw new InvalidOperationException($"Unknown navigation item tag: {item.Tag}");
            }
        }
    }
}
