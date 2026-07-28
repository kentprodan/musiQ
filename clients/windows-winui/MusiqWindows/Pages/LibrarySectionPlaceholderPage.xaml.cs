using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;

namespace MusiqWindows.Pages;

// One reusable placeholder for every section (Artists/Albums/Genres/Years/
// Record Labels/Playlists) under every library group (Local/Navidrome/Plex)
// that doesn't have a real implementation yet — 18 combinations minus the
// one that does (Local > Tracks, which is LibraryPage) would otherwise mean
// 17 near-identical page classes.
public sealed partial class LibrarySectionPlaceholderPage : Page
{
    public LibrarySectionPlaceholderPage()
    {
        InitializeComponent();
    }

    protected override void OnNavigatedTo(NavigationEventArgs e)
    {
        base.OnNavigatedTo(e);
        if (e.Parameter is (string section, string source))
        {
            TitleText.Text = section;
            SubtitleText.Text = $"Coming soon — {section.ToLowerInvariant()} browsing for {source} isn't implemented yet.";
        }
    }
}
