using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;
using MusiqWindows.Services;
using MusiqWindows.ViewModels;
using UniffiNavidromeAlbum = uniffi.musiq_uniffi.NavidromeAlbum;
using UniffiNavidromeArtist = uniffi.musiq_uniffi.NavidromeArtist;
using UniffiNavidromeFolder = uniffi.musiq_uniffi.NavidromeFolder;
using UniffiNavidromeSong = uniffi.musiq_uniffi.NavidromeSong;
using UniffiPlexAlbum = uniffi.musiq_uniffi.PlexAlbum;
using UniffiPlexArtist = uniffi.musiq_uniffi.PlexArtist;
using UniffiPlexLibrary = uniffi.musiq_uniffi.PlexLibrary;
using UniffiPlexTrack = uniffi.musiq_uniffi.PlexTrack;

namespace MusiqWindows.Pages;

internal sealed partial class SourcesPage : Page
{
    public SourcesViewModel ViewModel { get; } = new();

    public SourcesPage()
    {
        InitializeComponent();
        _ = AutoConnectAsync();
    }

    protected override void OnNavigatedTo(NavigationEventArgs e)
    {
        base.OnNavigatedTo(e);
        // Refresh every time the page is shown, since a scan on the Library
        // page may have added a new source since our last visit.
        _ = ViewModel.RefreshCommand.ExecuteAsync(null);
    }

    /// Reconnects to whichever servers were saved from a previous session,
    /// or — since the Plex/Navidrome services are app-lifetime singletons
    /// but this page (and its ViewModel) is recreated on every visit — just
    /// re-syncs this page's display from an already-live connection left
    /// over from an earlier visit, rather than reconnecting over the network.
    private async Task AutoConnectAsync()
    {
        if (PlexService.Instance.IsConnected)
        {
            if (CredentialStore.LoadPlex() is (var url, var token))
            {
                PlexServerUrlBox.Text = url;
                PlexTokenBox.Password = token;
            }
            await ViewModel.RefreshPlexBrowseStateAsync();
        }
        else if (CredentialStore.LoadPlex() is (var plexUrl, var plexToken))
        {
            PlexServerUrlBox.Text = plexUrl;
            PlexTokenBox.Password = plexToken;
            await ViewModel.ConnectToPlexAsync(plexUrl, plexToken);
        }

        if (NavidromeService.Instance.IsConnected)
        {
            if (CredentialStore.LoadNavidrome() is (var url, var user, var password))
            {
                NavidromeServerUrlBox.Text = url;
                NavidromeUsernameBox.Text = user;
                NavidromePasswordBox.Password = password;
            }
            await ViewModel.RefreshNavidromeBrowseStateAsync();
        }
        else if (CredentialStore.LoadNavidrome() is (var navUrl, var navUser, var navPassword))
        {
            NavidromeServerUrlBox.Text = navUrl;
            NavidromeUsernameBox.Text = navUser;
            NavidromePasswordBox.Password = navPassword;
            await ViewModel.ConnectToNavidromeAsync(navUrl, navUser, navPassword);
        }
    }

    private async void PlexConnectButton_Click(object sender, RoutedEventArgs e)
    {
        await ViewModel.ConnectToPlexAsync(PlexServerUrlBox.Text, PlexTokenBox.Password);
    }

    private async void PlexLibraryButton_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: UniffiPlexLibrary library })
        {
            await ViewModel.LoadPlexLibraryAsync(library);
        }
    }

    private async void PlexArtistButton_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: UniffiPlexArtist artist })
        {
            await ViewModel.LoadPlexArtistAsync(artist);
        }
    }

    private async void PlexAlbumButton_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: UniffiPlexAlbum album })
        {
            await ViewModel.LoadPlexAlbumAsync(album);
        }
    }

    private async void PlexTrackPlayButton_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: UniffiPlexTrack track })
        {
            await ViewModel.PlayPlexTrackAsync(track);
        }
    }

    private async void NavidromeConnectButton_Click(object sender, RoutedEventArgs e)
    {
        await ViewModel.ConnectToNavidromeAsync(
            NavidromeServerUrlBox.Text, NavidromeUsernameBox.Text, NavidromePasswordBox.Password);
    }

    private async void NavidromeFolderButton_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: UniffiNavidromeFolder folder })
        {
            await ViewModel.LoadNavidromeFolderAsync(folder);
        }
    }

    private async void NavidromeArtistButton_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: UniffiNavidromeArtist artist })
        {
            await ViewModel.LoadNavidromeArtistAsync(artist);
        }
    }

    private async void NavidromeAlbumButton_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: UniffiNavidromeAlbum album })
        {
            await ViewModel.LoadNavidromeAlbumAsync(album);
        }
    }

    private async void NavidromeSongPlayButton_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: UniffiNavidromeSong song })
        {
            await ViewModel.PlayNavidromeSongAsync(song);
        }
    }
}
