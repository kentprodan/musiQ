using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media.Imaging;
using MusiqWindows.Pages;
using MusiqWindows.Services;
using MusiqWindows.ViewModels;

// To learn more about WinUI, the WinUI project structure,
// and more about our project templates, see: http://aka.ms/winui-project-info.

namespace MusiqWindows;

public sealed partial class MainWindow : Window
{
    private enum LibrarySource
    {
        Local,
        Navidrome,
        Plex,
    }

    private sealed record LibrarySection(string Tag, string Name, string Glyph);

    private LibrarySource _currentLibrarySource = LibrarySource.Local;

    // Each source's items are a flat NavigationViewItemHeader + NavigationViewItems
    // (not a subtree — a plain list) so the Navidrome/Plex ones can be
    // hidden/shown together as a block when connection state changes.
    private List<NavigationViewItemBase>? _localSectionItems;
    private List<NavigationViewItemBase>? _navidromeSectionItems;
    private List<NavigationViewItemBase>? _plexSectionItems;

    // The one actual subtree in the menu — Playlists isn't per-source, it
    // just shows playlists for whichever source the title bar's library
    // picker currently has selected, so its label/child is refreshed
    // whenever that selection changes rather than being duplicated 3x.
    private NavigationViewItem? _playlistsItem;

    // Tracks which section is currently open (e.g. "Tracks", "Albums",
    // "Playlists"), or null on pages that aren't a library section at all
    // (Now Playing, Downloads, Offline, Settings). Set in NavigateToTag —
    // the title bar search box's visibility and "Search {Source} {Section}"
    // placeholder are both derived from this plus _currentLibrarySource.
    private string? _currentSectionName;

    public MainWindow()
    {
        InitializeComponent();

        // Applied here (rather than only from Settings) so the saved choice
        // takes effect immediately at launch, before App.MainAppWindow even
        // exists — Settings' own theme change applies the same way later,
        // just via App.MainAppWindow.Content instead of this direct reference.
        RootGrid.RequestedTheme = SettingsViewModel.LoadSavedTheme();
        SettingsViewModel.ApplySoundEnabled(SettingsViewModel.LoadSavedSoundEnabled());

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

        RootGrid.ActualThemeChanged += (_, _) => UpdateLibrarySourceDisplay();
        UpdateLibrarySourceDisplay();

        BuildLibraryMenuItems();
    }

    // The title bar's search box only makes sense on a library section page,
    // so it's hidden on Now Playing/Downloads/Offline/Settings rather than
    // left visible-but-inert there. Its placeholder names the section and
    // source currently open (e.g. "Search Plex Albums") — _currentSectionName
    // is set by NavigateToTag right before this runs.
    private void NavFrame_Navigated(object sender, Microsoft.UI.Xaml.Navigation.NavigationEventArgs e)
    {
        if (_currentSectionName is not null)
        {
            LibrarySearchBox.Visibility = Visibility.Visible;
            LibrarySearchBox.PlaceholderText = $"Search {LibrarySourceText.Text} {_currentSectionName}";
            LibrarySearchBox.Text = NavFrame.Content is LibraryPage libraryPage ? libraryPage.ViewModel.FilterText : string.Empty;
        }
        else
        {
            LibrarySearchBox.Visibility = Visibility.Collapsed;
            LibrarySearchBox.Text = string.Empty;
        }

        // Connecting/disconnecting Plex or Navidrome happens inside Settings
        // (a nested Frame), so this is the next point after leaving Settings
        // where it's safe to notice the change — cheap, since it only flips
        // Visibility on the section blocks rather than rebuilding anything.
        RefreshLibrarySectionVisibility();
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
    internal const string WindowWidthSetting = "WindowWidth";
    internal const string WindowHeightSetting = "WindowHeight";

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

    // Navidrome/Plex ship separate dark- and light-themed icon files (a
    // dark-colored mark for a light background, a light-colored one for
    // dark) rather than a single tintable glyph, so the correct file has to
    // be picked in code and re-picked on every theme change. "Local" uses
    // the standard Segoe Fluent Audio glyph instead, which colors itself.
    private static Uri NavidromeIconUri(ElementTheme theme) =>
        new(theme == ElementTheme.Dark ? "ms-appx:///Assets/NavidromeIconLight.png" : "ms-appx:///Assets/NavidromeIconDark.png");

    private static Uri PlexIconUri(ElementTheme theme) =>
        new(theme == ElementTheme.Dark ? "ms-appx:///Assets/PlexIconLight.png" : "ms-appx:///Assets/PlexIconDark.png");

    private void UpdateLibrarySourceDisplay()
    {
        var theme = RootGrid.ActualTheme;
        string name;
        switch (_currentLibrarySource)
        {
            case LibrarySource.Navidrome:
                LibrarySourceFontIcon.Visibility = Visibility.Collapsed;
                LibrarySourceImage.Visibility = Visibility.Visible;
                LibrarySourceImage.Source = new BitmapImage(NavidromeIconUri(theme));
                name = "Navidrome";
                break;
            case LibrarySource.Plex:
                LibrarySourceFontIcon.Visibility = Visibility.Collapsed;
                LibrarySourceImage.Visibility = Visibility.Visible;
                LibrarySourceImage.Source = new BitmapImage(PlexIconUri(theme));
                name = "Plex";
                break;
            default:
                LibrarySourceImage.Visibility = Visibility.Collapsed;
                LibrarySourceFontIcon.Visibility = Visibility.Visible;
                name = "Local";
                break;
        }

        LibrarySourceText.Text = name;

        // Offline playback only makes sense for a streamed source — local
        // files are already "offline" by definition.
        OfflineNavItem.Visibility = _currentLibrarySource == LibrarySource.Local
            ? Visibility.Collapsed
            : Visibility.Visible;

        UpdatePlaylistsItem();
    }

    private void SelectLibrarySource(LibrarySource source)
    {
        _currentLibrarySource = source;
        UpdateLibrarySourceDisplay();
        RefreshLibrarySectionVisibility();

        // Jump straight to that source's Tracks section so there's
        // something relevant on screen the moment you switch.
        var tag = source switch
        {
            LibrarySource.Navidrome => "navidrome|tracks",
            LibrarySource.Plex => "plex|tracks",
            _ => "local|tracks",
        };
        var item = NavView.MenuItems.OfType<NavigationViewItem>().FirstOrDefault(i => (string?)i.Tag == tag);
        if (item is not null)
        {
            NavView.SelectedItem = item;
            NavigateToTag(tag);
        }
    }

    private void LibrarySourceButton_Click(SplitButton sender, SplitButtonClickEventArgs args)
    {
        SelectLibrarySource(_currentLibrarySource);
    }

    // The pane's global search box always resolves to Local Tracks — the
    // only section with real searchable data today — rather than whatever
    // section happened to be open when the query was submitted.
    private void GlobalSearchBox_QuerySubmitted(AutoSuggestBox sender, AutoSuggestBoxQuerySubmittedEventArgs args)
    {
        SelectLibrarySource(LibrarySource.Local);
        if (NavFrame.Content is LibraryPage libraryPage)
        {
            libraryPage.ViewModel.FilterText = args.QueryText;
            LibrarySearchBox.Text = args.QueryText;
        }
    }

    // Rebuilt on every open since Plex/Navidrome connection state can change
    // between visits (connect/disconnect in Settings).
    private void LibrarySourceFlyout_Opening(object sender, object e)
    {
        LibrarySourceFlyout.Items.Clear();
        var theme = RootGrid.ActualTheme;

        var localItem = new MenuFlyoutItem
        {
            Text = "Local",
            Icon = new FontIcon { Glyph = "" },
        };
        localItem.Click += (_, _) => SelectLibrarySource(LibrarySource.Local);
        LibrarySourceFlyout.Items.Add(localItem);

        if (NavidromeService.Instance.IsConnected)
        {
            var navidromeItem = new MenuFlyoutItem
            {
                Text = "Navidrome",
                Icon = new ImageIcon { Source = new BitmapImage(NavidromeIconUri(theme)) },
            };
            navidromeItem.Click += (_, _) => SelectLibrarySource(LibrarySource.Navidrome);
            LibrarySourceFlyout.Items.Add(navidromeItem);
        }

        if (PlexService.Instance.IsConnected)
        {
            var plexItem = new MenuFlyoutItem
            {
                Text = "Plex",
                Icon = new ImageIcon { Source = new BitmapImage(PlexIconUri(theme)) },
            };
            plexItem.Click += (_, _) => SelectLibrarySource(LibrarySource.Plex);
            LibrarySourceFlyout.Items.Add(plexItem);
        }
    }

    private void TitleBar_PaneToggleRequested(TitleBar sender, object args)
    {
        NavView.IsPaneOpen = !NavView.IsPaneOpen;
        ElementSoundPlayer.Play(NavView.IsPaneOpen ? ElementSoundKind.Show : ElementSoundKind.Hide);
    }

    private void TitleBar_BackRequested(TitleBar sender, object args)
    {
        ElementSoundPlayer.Play(ElementSoundKind.GoBack);
        NavFrame.GoBack();
    }

    // Same section list for every source right now — per-library
    // customization (letting the user pick which sections show for which
    // library) is planned but not built yet. Keeping this as a lookup
    // method rather than one flat list means future work only changes what
    // this returns, not how a source's block gets built.
    private static IReadOnlyList<LibrarySection> GetLibrarySections() => new[]
    {
        new LibrarySection("tracks", "Tracks", ""),
        new LibrarySection("albums", "Albums", ""),
        new LibrarySection("artists", "Artists", ""),
        new LibrarySection("genres", "Genres", ""),
        new LibrarySection("years", "Years", ""),
        new LibrarySection("labels", "Record Labels", ""),
    };

    // A NavigationViewItemHeader (plain section label, no expand/collapse)
    // followed by one flat NavigationViewItem per section — "{source}|{section}"
    // tags let a single NavigateToTag switch handle every combination.
    private List<NavigationViewItemBase> BuildLibrarySectionItems(string sourceTag, string headerText)
    {
        var items = new List<NavigationViewItemBase>
        {
            new NavigationViewItemHeader { Content = headerText },
        };

        foreach (var section in GetLibrarySections())
        {
            items.Add(new NavigationViewItem
            {
                Content = section.Name,
                Tag = $"{sourceTag}|{section.Tag}",
                Icon = new FontIcon { Glyph = section.Glyph },
            });
        }

        return items;
    }

    private void BuildLibraryMenuItems()
    {
        NavView.MenuItems.Clear();

        _localSectionItems = BuildLibrarySectionItems("local", "Local");
        foreach (var item in _localSectionItems)
        {
            NavView.MenuItems.Add(item);
        }

        _navidromeSectionItems = BuildLibrarySectionItems("navidrome", "Navidrome");
        foreach (var item in _navidromeSectionItems)
        {
            NavView.MenuItems.Add(item);
        }

        _plexSectionItems = BuildLibrarySectionItems("plex", "Plex");
        foreach (var item in _plexSectionItems)
        {
            NavView.MenuItems.Add(item);
        }

        _playlistsItem = new NavigationViewItem
        {
            Content = "Playlists",
            Tag = "playlists",
            Icon = new FontIcon { Glyph = "" },
        };
        _playlistsItem.MenuItems.Add(new NavigationViewItem { IsEnabled = false });
        NavView.MenuItems.Add(_playlistsItem);

        RefreshLibrarySectionVisibility();
        UpdatePlaylistsItem();

        // Default to Local > Tracks on launch.
        var tracksItem = NavView.MenuItems
            .OfType<NavigationViewItem>()
            .FirstOrDefault(item => (string?)item.Tag == "local|tracks");
        if (tracksItem is not null)
        {
            NavView.SelectedItem = tracksItem;
            NavigateToTag("local|tracks");
        }
    }

    // Only the currently selected library's section shows at a time — not
    // "every connected source at once" — so switching the title bar's
    // library picker hides the others rather than just adding to them.
    private void RefreshLibrarySectionVisibility()
    {
        SetVisibility(_localSectionItems, _currentLibrarySource == LibrarySource.Local);
        SetVisibility(_navidromeSectionItems, _currentLibrarySource == LibrarySource.Navidrome && NavidromeService.Instance.IsConnected);
        SetVisibility(_plexSectionItems, _currentLibrarySource == LibrarySource.Plex && PlexService.Instance.IsConnected);
    }

    private static void SetVisibility(List<NavigationViewItemBase>? items, bool visible)
    {
        if (items is null)
        {
            return;
        }

        var visibility = visible ? Visibility.Visible : Visibility.Collapsed;
        foreach (var item in items)
        {
            item.Visibility = visibility;
        }
    }

    // Playlists isn't split per source like the other sections — there's
    // just one entry, and it tracks whichever source the title bar's
    // library picker currently has selected (no real playlist data exists
    // anywhere yet, so the child is always the same placeholder for now).
    private void UpdatePlaylistsItem()
    {
        if (_playlistsItem is null)
        {
            return;
        }

        var sourceName = _currentLibrarySource switch
        {
            LibrarySource.Navidrome => "Navidrome",
            LibrarySource.Plex => "Plex",
            _ => "Local",
        };

        if (_playlistsItem.MenuItems is [NavigationViewItem placeholder])
        {
            placeholder.Content = $"No {sourceName} playlists yet";
        }
    }

    private static readonly Dictionary<string, string> SourceDisplayNames = new()
    {
        ["local"] = "Local",
        ["navidrome"] = "Navidrome",
        ["plex"] = "Plex",
    };

    private static readonly Dictionary<string, string> SectionDisplayNames = new()
    {
        ["tracks"] = "Tracks",
        ["albums"] = "Albums",
        ["artists"] = "Artists",
        ["genres"] = "Genres",
        ["years"] = "Years",
        ["labels"] = "Record Labels",
    };

    private void NavigateToTag(string tag)
    {
        switch (tag)
        {
            case "nowplaying":
                _currentSectionName = null;
                NavFrame.Navigate(typeof(NowPlayingPage));
                AppTitleBar.Subtitle = "Now Playing";
                return;
            case "offline":
                _currentSectionName = null;
                NavFrame.Navigate(typeof(OfflinePage));
                AppTitleBar.Subtitle = "Offline";
                return;
            case "downloads":
                _currentSectionName = null;
                NavFrame.Navigate(typeof(DownloadsPage));
                AppTitleBar.Subtitle = "Downloads";
                return;
            case "playlists":
                var currentSourceName = _currentLibrarySource switch
                {
                    LibrarySource.Navidrome => "Navidrome",
                    LibrarySource.Plex => "Plex",
                    _ => "Local",
                };
                _currentSectionName = "Playlists";
                NavFrame.Navigate(typeof(LibrarySectionPlaceholderPage), ("Playlists", currentSourceName));
                AppTitleBar.Subtitle = $"{currentSourceName} – Playlists";
                return;
        }

        var parts = tag.Split('|', 2);
        if (parts.Length != 2 || !SourceDisplayNames.TryGetValue(parts[0], out var sourceName) ||
            !SectionDisplayNames.TryGetValue(parts[1], out var sectionName))
        {
            throw new InvalidOperationException($"Unknown navigation item tag: {tag}");
        }

        _currentSectionName = sectionName;

        if (tag == "local|tracks")
        {
            NavFrame.Navigate(typeof(LibraryPage));
        }
        else
        {
            NavFrame.Navigate(typeof(LibrarySectionPlaceholderPage), (sectionName, sourceName));
        }

        AppTitleBar.Subtitle = $"{sourceName} – {sectionName}";
    }

    private void NavView_SelectionChanged(NavigationView sender, NavigationViewSelectionChangedEventArgs args)
    {
        if (args.IsSettingsSelected)
        {
            _currentSectionName = null;
            NavFrame.Navigate(typeof(SettingsPage));
            AppTitleBar.Subtitle = "Settings";
        }
        else if (args.SelectedItem is NavigationViewItem { Tag: string tag })
        {
            NavigateToTag(tag);
        }
    }
}
