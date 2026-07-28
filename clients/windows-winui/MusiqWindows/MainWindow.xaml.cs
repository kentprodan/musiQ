using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using MusiqWindows.Pages;
using MusiqWindows.Services;
using MusiqWindows.ViewModels;

// To learn more about WinUI, the WinUI project structure,
// and more about our project templates, see: http://aka.ms/winui-project-info.

namespace MusiqWindows;

public sealed partial class MainWindow : Window
{
    // Which sources the title bar search box's scope covers. Library is the
    // only one actually wired to search results right now — Navidrome and
    // Plex only support hierarchical browsing in the core today, not
    // free-text search, so those toggles just record intent until that
    // backend work lands.
    private bool _searchInNavidrome;
    private bool _searchInPlex;

    public MainWindow()
    {
        InitializeComponent();

        ExtendsContentIntoTitleBar = true;
        SetTitleBar(AppTitleBar);
        AppWindow.TitleBar.PreferredHeightOption = TitleBarHeightOption.Tall;
        AppWindow.SetIcon("Assets/AppIcon.ico");

        // Below this, the Library toolbar's buttons (Scan/Edit/Rename/Sort) start
        // overlapping since that row is a non-wrapping StackPanel.
        if (AppWindow.Presenter is OverlappedPresenter presenter)
        {
            presenter.PreferredMinimumWidth = 800;
            presenter.PreferredMinimumHeight = 600;
        }

        RestoreWindowSize();
        Closed += MainWindow_Closed;

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
            SearchPanel.Visibility = Visibility.Visible;
            LibrarySearchBox.Text = libraryPage.ViewModel.FilterText;
        }
        else
        {
            SearchPanel.Visibility = Visibility.Collapsed;
            LibrarySearchBox.Text = string.Empty;
        }

        AppTitleBar.Subtitle = NavFrame.Content switch
        {
            LibraryPage => "Library",
            NowPlayingPage => "Now Playing",
            SourcesPage => "Sources",
            SettingsPage => "Settings",
            _ => string.Empty,
        };
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

    // Window size is remembered across restarts via LocalSettings (the
    // official lightweight per-user storage for a packaged app). AppWindow
    // sizes are raw/physical pixels, so saving and restoring through the
    // same AppWindow.Size/Resize pair needs no DPI conversion.
    private const string WindowWidthSetting = "WindowWidth";
    private const string WindowHeightSetting = "WindowHeight";

    private void RestoreWindowSize()
    {
        var settings = Windows.Storage.ApplicationData.Current.LocalSettings.Values;
        if (settings[WindowWidthSetting] is int width && settings[WindowHeightSetting] is int height)
        {
            AppWindow.Resize(new Windows.Graphics.SizeInt32(width, height));
        }
    }

    private void MainWindow_Closed(object sender, WindowEventArgs args)
    {
        // Skip saving while maximized/minimized so the remembered size stays
        // the last "restored" (normal) size rather than a maximized one.
        if (AppWindow.Presenter is OverlappedPresenter { State: OverlappedPresenterState.Restored })
        {
            var settings = Windows.Storage.ApplicationData.Current.LocalSettings.Values;
            settings[WindowWidthSetting] = AppWindow.Size.Width;
            settings[WindowHeightSetting] = AppWindow.Size.Height;
        }
    }

    // TitleBar.Content is sized to its content's desired width, not stretched
    // to fill the bar — there's no official star-sizing for it — so the
    // search box's width is driven proportionally from the window's own
    // resize event instead: ~30% of window width, clamped to a readable
    // range, wider than the previous fixed 320px cap but never so wide it
    // crowds the caption buttons on an 800px-minimum window.
    private void RootGrid_SizeChanged(object sender, SizeChangedEventArgs e)
    {
        LibrarySearchBox.Width = Math.Clamp(e.NewSize.Width * 0.3, 200, 480);
    }

    private void SearchScopeButton_Click(SplitButton sender, SplitButtonClickEventArgs args)
    {
        LibrarySearchBox.Focus(FocusState.Programmatic);
    }

    private void SearchScopeButton_PointerEntered(object sender, PointerRoutedEventArgs e)
    {
        AnimatedIcon.SetState(SearchScopeIcon, "PointerOver");
    }

    private void SearchScopeButton_PointerExited(object sender, PointerRoutedEventArgs e)
    {
        AnimatedIcon.SetState(SearchScopeIcon, "Normal");
    }

    // Rebuilt on every open since Plex/Navidrome connection state can change
    // between visits (connect/disconnect on the Sources page).
    private void SearchScopeFlyout_Opening(object sender, object e)
    {
        SearchScopeFlyout.Items.Clear();

        SearchScopeFlyout.Items.Add(new ToggleMenuFlyoutItem
        {
            Text = "Library",
            IsChecked = true,
            IsEnabled = false,
        });

        if (NavidromeService.Instance.IsConnected)
        {
            var navidromeItem = new ToggleMenuFlyoutItem { Text = "Navidrome", IsChecked = _searchInNavidrome };
            navidromeItem.Click += (s, _) => _searchInNavidrome = ((ToggleMenuFlyoutItem)s).IsChecked;
            SearchScopeFlyout.Items.Add(navidromeItem);
        }

        if (PlexService.Instance.IsConnected)
        {
            var plexItem = new ToggleMenuFlyoutItem { Text = "Plex", IsChecked = _searchInPlex };
            plexItem.Click += (s, _) => _searchInPlex = ((ToggleMenuFlyoutItem)s).IsChecked;
            SearchScopeFlyout.Items.Add(plexItem);
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
