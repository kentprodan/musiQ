using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;
using MusiqWindows.ViewModels;
using UniffiNavidromeAlbum = uniffi.musiq_uniffi.NavidromeAlbum;
using UniffiNavidromeFolder = uniffi.musiq_uniffi.NavidromeFolder;
using UniffiNavidromeSong = uniffi.musiq_uniffi.NavidromeSong;
using UniffiPlexLibrary = uniffi.musiq_uniffi.PlexLibrary;
using UniffiPlexTrack = uniffi.musiq_uniffi.PlexTrack;

namespace MusiqWindows.Pages;

internal sealed partial class SourcesPage : Page
{
    public SourcesViewModel ViewModel { get; } = new();

    public SourcesPage()
    {
        InitializeComponent();
    }

    protected override void OnNavigatedTo(NavigationEventArgs e)
    {
        base.OnNavigatedTo(e);
        // Refresh every time the page is shown, since a scan on the Library
        // page may have added a new source since our last visit.
        _ = ViewModel.RefreshCommand.ExecuteAsync(null);
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
