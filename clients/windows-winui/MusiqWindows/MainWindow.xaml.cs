using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using MusiqWindows.Pages;
using MusiqWindows.ViewModels;

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

        NavFrame.Navigated += NavFrame_Navigated;

        // NavigationView.IsSelected on the initial item doesn't raise SelectionChanged,
        // so the Frame needs an explicit first navigation or it starts empty.
        NavFrame.Navigate(typeof(LibraryPage));
    }

    // The title bar's search box only makes sense on the Library page, so it's
    // hidden/cleared on every other page rather than left visible-but-inert.
    private void NavFrame_Navigated(object sender, Microsoft.UI.Xaml.Navigation.NavigationEventArgs e)
    {
        if (NavFrame.Content is LibraryPage libraryPage)
        {
            LibrarySearchBox.Visibility = Visibility.Visible;
            LibrarySearchBox.Text = libraryPage.ViewModel.FilterText;
        }
        else
        {
            LibrarySearchBox.Visibility = Visibility.Collapsed;
            LibrarySearchBox.Text = string.Empty;
        }
    }

    private void LibrarySearchBox_TextChanged(AutoSuggestBox sender, AutoSuggestBoxTextChangedEventArgs args)
    {
        if (args.Reason != AutoSuggestionBoxTextChangeReason.UserInput)
        {
            return;
        }

        if (NavFrame.Content is LibraryPage libraryPage)
        {
            libraryPage.ViewModel.FilterText = sender.Text;
        }
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
