using Microsoft.UI.Input;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Controls.Primitives;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using MusiqWindows.ViewModels;
using Windows.Storage.Pickers;
using WinRT.Interop;

namespace MusiqWindows.Pages;

public sealed partial class LibraryPage : Page
{
    public LibraryViewModel ViewModel { get; } = new();

    private const string ColumnsLayoutSetting = "TrackColumnsLayout";

    private readonly List<TrackColumn> _columns;
    private bool _showSelectionCheckboxes;
    private Grid? _headerGrid;
    private readonly Brush? _alternateRowBrush;

    // Column-resize drag state — set on PointerPressed over a resize handle,
    // cleared on PointerReleased. Once a handle has pointer capture, only it
    // receives PointerMoved regardless of where the pointer actually is, so
    // "are we dragging" reduces to "is this non-null".
    private TrackColumn? _resizingColumn;
    private double _resizeStartX;
    private double _resizeStartWidth;

    /// Which track the "more" (⋯) flyout is currently open for — MenuFlyout
    /// isn't a FrameworkElement, so it has no Tag of its own to stash this on.
    private TrackItem? _moreFlyoutTrack;

    /// A Grid that can actually set its own cursor — UIElement.ProtectedCursor
    /// is protected, so a plain element can't be given a resize cursor from
    /// outside; subclassing is the documented workaround. Grid (not Border,
    /// which is sealed in WinAppSDK) just for a hit-testable, background-
    /// paintable surface.
    private sealed class ResizeHandle : Grid
    {
        public ResizeHandle()
        {
            ProtectedCursor = InputSystemCursor.Create(InputSystemCursorShape.SizeWestEast);
        }
    }

    /// Cached lookups into one realized row's named template children —
    /// stashed on the row's ListViewItem.Tag (not the inner Grid's Tag, which
    /// already holds the bound TrackItem) so repeated ContainerContentChanging
    /// calls during virtualization/scrolling don't repeat FindName on every pass.
    private sealed class RowElements
    {
        public required Button PlayButton { get; init; }
        public required Button MoreButton { get; init; }
        public required TextBlock TitleText { get; init; }
        public required TextBlock TimeText { get; init; }
        public required TextBlock ArtistText { get; init; }
        public required TextBlock AlbumText { get; init; }
        public required TextBlock YearText { get; init; }
        public required TextBlock GenreText { get; init; }
    }

    public LibraryPage()
    {
        InitializeComponent();
        // Needed only so the per-row Play button's `Tag="{x:Bind}"` sibling
        // pattern has a page-level ViewModel to reach for commands that
        // aren't per-row (e.g. dialogs) — every other binding here is x:Bind.
        LibraryPageRoot.DataContext = ViewModel;

        _columns = LoadColumns();
        _showSelectionCheckboxes = SettingsViewModel.LoadSavedShowTrackSelectionCheckboxes();
        SelectionCheckboxesToggle.IsChecked = _showSelectionCheckboxes;
        ApplySelectionMode();

        // Best-effort: a slightly-off alternating-row color is a cosmetic
        // miss, not worth failing page construction over.
        Application.Current.Resources.TryGetValue("SubtleFillColorSecondaryBrush", out var brush);
        _alternateRowBrush = brush as Brush;

        RebuildHeader();
    }

    // ===== Column model: defaults, persistence =====

    private sealed record ColumnLayoutEntry(double Width, bool IsVisible);

    private static List<TrackColumn> LoadColumns()
    {
        var columns = new List<TrackColumn>
        {
            new(TrackColumnKey.Title, "Title", 280, 120, canHide: false),
            new(TrackColumnKey.Time, "Time", 70, 50),
            new(TrackColumnKey.Artist, "Artist", 180, 80),
            new(TrackColumnKey.Album, "Album", 180, 80),
            new(TrackColumnKey.Year, "Year", 70, 50),
            new(TrackColumnKey.Genre, "Genre", 120, 60),
        };

        if (Windows.Storage.ApplicationData.Current.LocalSettings.Values[ColumnsLayoutSetting] is not string saved)
        {
            return columns;
        }

        try
        {
            var entries = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, ColumnLayoutEntry>>(saved);
            if (entries is null)
            {
                return columns;
            }

            foreach (var column in columns)
            {
                if (!entries.TryGetValue(column.Key.ToString(), out var entry))
                {
                    continue;
                }

                column.Width = Math.Max(column.MinWidth, entry.Width);
                if (column.CanHide)
                {
                    column.IsVisible = entry.IsVisible;
                }
            }
        }
        catch (System.Text.Json.JsonException)
        {
            // Corrupt or old-format saved layout — fall back to defaults.
        }

        return columns;
    }

    private void SaveColumns()
    {
        var entries = _columns.ToDictionary(
            c => c.Key.ToString(),
            c => new ColumnLayoutEntry(c.Width, c.IsVisible));
        Windows.Storage.ApplicationData.Current.LocalSettings.Values[ColumnsLayoutSetting] =
            System.Text.Json.JsonSerializer.Serialize(entries);
    }

    // ===== Header: build, sort, resize, show/hide =====

    /// The header is a plain code-built Grid assigned to ListView.Header —
    /// dynamic per-column visibility/order isn't expressible from a static
    /// XAML HeaderTemplate, so it's rebuilt in code whenever columns change.
    private void RebuildHeader()
    {
        var header = new Grid();
        header.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(36) });

        var visible = _columns.Where(c => c.IsVisible).ToList();
        foreach (var column in visible)
        {
            header.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(column.Width) });
        }

        header.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(36) });

        var columnIndex = 1;
        foreach (var column in visible)
        {
            var headerButton = new Button
            {
                Content = BuildHeaderButtonContent(column),
                HorizontalAlignment = HorizontalAlignment.Stretch,
                HorizontalContentAlignment = HorizontalAlignment.Left,
                Background = new SolidColorBrush(Microsoft.UI.Colors.Transparent),
                BorderThickness = new Thickness(0),
                Padding = new Thickness(12, 4, 4, 4),
                Tag = column,
            };
            headerButton.Click += HeaderColumnButton_Click;
            Grid.SetColumn(headerButton, columnIndex);
            header.Children.Add(headerButton);

            if (!ReferenceEquals(column, visible[^1]))
            {
                var resizer = new ResizeHandle
                {
                    Width = 8,
                    HorizontalAlignment = HorizontalAlignment.Right,
                    Background = new SolidColorBrush(Microsoft.UI.Colors.Transparent),
                    Tag = column,
                };
                resizer.PointerPressed += ColumnResizer_PointerPressed;
                resizer.PointerMoved += ColumnResizer_PointerMoved;
                resizer.PointerReleased += ColumnResizer_PointerReleased;
                Grid.SetColumn(resizer, columnIndex);
                header.Children.Add(resizer);
            }

            columnIndex++;
        }

        header.RightTapped += Header_RightTapped;

        _headerGrid = header;
        TracksListView.Header = header;
    }

    private object BuildHeaderButtonContent(TrackColumn column)
    {
        var panel = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 4 };
        panel.Children.Add(new TextBlock { Text = column.Header, FontWeight = Microsoft.UI.Text.FontWeights.SemiBold });

        if (ViewModel.SortField == TrackColumn.ToSortField(column.Key))
        {
            panel.Children.Add(new FontIcon
            {
                FontFamily = new FontFamily("Segoe Fluent Icons"),
                // ChevronUp (ascending) / ChevronDown (descending), per Segoe Fluent Icons.
                Glyph = ViewModel.SortDescending ? "" : "",
                FontSize = 10,
                VerticalAlignment = VerticalAlignment.Center,
            });
        }

        return panel;
    }

    private void HeaderColumnButton_Click(object sender, RoutedEventArgs e)
    {
        if (sender is not FrameworkElement { Tag: TrackColumn column })
        {
            return;
        }

        var sortField = TrackColumn.ToSortField(column.Key);
        if (ViewModel.SortField == sortField)
        {
            ViewModel.SortDescending = !ViewModel.SortDescending;
        }
        else
        {
            ViewModel.SortField = sortField;
            ViewModel.SortDescending = false;
        }

        RebuildHeader();
    }

    private void ColumnResizer_PointerPressed(object sender, PointerRoutedEventArgs e)
    {
        if (sender is not FrameworkElement { Tag: TrackColumn column } element || _headerGrid is null)
        {
            return;
        }

        _resizingColumn = column;
        _resizeStartX = e.GetCurrentPoint(_headerGrid).Position.X;
        _resizeStartWidth = column.Width;
        element.CapturePointer(e.Pointer);
        e.Handled = true;
    }

    private void ColumnResizer_PointerMoved(object sender, PointerRoutedEventArgs e)
    {
        if (_resizingColumn is null || _headerGrid is null)
        {
            return;
        }

        var currentX = e.GetCurrentPoint(_headerGrid).Position.X;
        var newWidth = Math.Max(_resizingColumn.MinWidth, _resizeStartWidth + (currentX - _resizeStartX));
        _resizingColumn.Width = newWidth;

        var visibleIndex = _columns.Where(c => c.IsVisible).ToList().IndexOf(_resizingColumn);
        if (visibleIndex >= 0)
        {
            _headerGrid.ColumnDefinitions[visibleIndex + 1].Width = new GridLength(newWidth);
        }

        ApplyColumnLayoutToRealizedRows();
        e.Handled = true;
    }

    private void ColumnResizer_PointerReleased(object sender, PointerRoutedEventArgs e)
    {
        if (sender is UIElement element)
        {
            element.ReleasePointerCapture(e.Pointer);
        }

        if (_resizingColumn is not null)
        {
            SaveColumns();
        }

        _resizingColumn = null;
        e.Handled = true;
    }

    private void Header_RightTapped(object sender, RightTappedRoutedEventArgs e)
    {
        var flyout = new MenuFlyout();

        foreach (var column in _columns)
        {
            var item = new ToggleMenuFlyoutItem
            {
                Text = column.Header,
                IsChecked = column.IsVisible,
                IsEnabled = column.CanHide,
            };
            item.Click += (_, _) =>
            {
                column.IsVisible = item.IsChecked;
                SaveColumns();
                RebuildHeader();
                ApplyColumnLayoutToRealizedRows();
            };
            flyout.Items.Add(item);
        }

        flyout.Items.Add(new MenuFlyoutSeparator());

        var customizeItem = new MenuFlyoutItem { Text = "Customize columns…" };
        customizeItem.Click += async (_, _) => await ShowCustomizeColumnsDialogAsync();
        flyout.Items.Add(customizeItem);

        flyout.ShowAt((FrameworkElement)sender, e.GetPosition((FrameworkElement)sender));
    }

    private async void ColumnsButton_Click(object sender, RoutedEventArgs e) =>
        await ShowCustomizeColumnsDialogAsync();

    private async Task ShowCustomizeColumnsDialogAsync()
    {
        CustomizeColumnsPanel.Children.Clear();
        foreach (var column in _columns)
        {
            var checkBox = new CheckBox
            {
                Content = column.Header,
                IsChecked = column.IsVisible,
                IsEnabled = column.CanHide,
            };
            checkBox.Checked += (_, _) => SetColumnVisible(column, true);
            checkBox.Unchecked += (_, _) => SetColumnVisible(column, false);
            CustomizeColumnsPanel.Children.Add(checkBox);
        }

        CustomizeColumnsDialog.XamlRoot = XamlRoot;
        await CustomizeColumnsDialog.ShowAsync();
    }

    private void SetColumnVisible(TrackColumn column, bool visible)
    {
        column.IsVisible = visible;
        SaveColumns();
        RebuildHeader();
        ApplyColumnLayoutToRealizedRows();
    }

    // ===== Rows: layout, alternating color, hover reveal, double-click =====

    private void TracksListView_ContainerContentChanging(ListViewBase sender, ContainerContentChangingEventArgs args)
    {
        if (args.ItemContainer is not SelectorItem container || container.ContentTemplateRoot is not Grid root)
        {
            return;
        }

        ApplyRowLayout(container, root);

        root.Background = args.ItemIndex % 2 != 0 && _alternateRowBrush is not null
            ? _alternateRowBrush
            : new SolidColorBrush(Microsoft.UI.Colors.Transparent);
    }

    private void ApplyRowLayout(SelectorItem container, Grid root)
    {
        if (container.Tag is not RowElements elements)
        {
            elements = new RowElements
            {
                PlayButton = (Button)root.FindName("RowPlayButton"),
                MoreButton = (Button)root.FindName("RowMoreButton"),
                TitleText = (TextBlock)root.FindName("TitleText"),
                TimeText = (TextBlock)root.FindName("TimeText"),
                ArtistText = (TextBlock)root.FindName("ArtistText"),
                AlbumText = (TextBlock)root.FindName("AlbumText"),
                YearText = (TextBlock)root.FindName("YearText"),
                GenreText = (TextBlock)root.FindName("GenreText"),
            };
            container.Tag = elements;
        }

        root.ColumnDefinitions.Clear();
        root.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(36) });

        var visible = _columns.Where(c => c.IsVisible).ToList();
        foreach (var column in visible)
        {
            root.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(column.Width) });
        }

        root.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(36) });

        Grid.SetColumn(elements.PlayButton, 0);

        var cellByKey = new Dictionary<TrackColumnKey, TextBlock>
        {
            [TrackColumnKey.Title] = elements.TitleText,
            [TrackColumnKey.Time] = elements.TimeText,
            [TrackColumnKey.Artist] = elements.ArtistText,
            [TrackColumnKey.Album] = elements.AlbumText,
            [TrackColumnKey.Year] = elements.YearText,
            [TrackColumnKey.Genre] = elements.GenreText,
        };

        var columnIndex = 1;
        foreach (var column in visible)
        {
            var cell = cellByKey[column.Key];
            cell.Visibility = Visibility.Visible;
            Grid.SetColumn(cell, columnIndex);
            columnIndex++;
        }

        foreach (var column in _columns.Where(c => !c.IsVisible))
        {
            cellByKey[column.Key].Visibility = Visibility.Collapsed;
        }

        Grid.SetColumn(elements.MoreButton, columnIndex);
    }

    private void ApplyColumnLayoutToRealizedRows()
    {
        foreach (var item in TracksListView.Items)
        {
            if (TracksListView.ContainerFromItem(item) is SelectorItem { ContentTemplateRoot: Grid root } container)
            {
                ApplyRowLayout(container, root);
            }
        }
    }

    private static void SetHoverButtonsVisibility(Grid root, Visibility visibility)
    {
        if (root.FindName("RowPlayButton") is Button playButton)
        {
            playButton.Visibility = visibility;
        }

        if (root.FindName("RowMoreButton") is Button moreButton)
        {
            moreButton.Visibility = visibility;
        }
    }

    private void TrackRow_PointerEntered(object sender, PointerRoutedEventArgs e)
    {
        if (sender is Grid root)
        {
            SetHoverButtonsVisibility(root, Visibility.Visible);
        }
    }

    private void TrackRow_PointerExited(object sender, PointerRoutedEventArgs e)
    {
        if (sender is Grid root)
        {
            SetHoverButtonsVisibility(root, Visibility.Collapsed);
        }
    }

    private async void TrackRow_DoubleTapped(object sender, DoubleTappedRoutedEventArgs e)
    {
        if (sender is FrameworkElement { Tag: TrackItem track })
        {
            await ViewModel.PlayTrackCommand.ExecuteAsync(track);
        }
    }

    private async void RowPlayButton_Click(object sender, RoutedEventArgs e)
    {
        if (sender is FrameworkElement { Tag: TrackItem track })
        {
            await ViewModel.PlayTrackCommand.ExecuteAsync(track);
        }
    }

    private void RowMoreButton_Click(object sender, RoutedEventArgs e)
    {
        if (sender is not FrameworkElement { Tag: TrackItem track } button)
        {
            return;
        }

        _moreFlyoutTrack = track;
        RowMoreFlyout.ShowAt(button);
    }

    private async void RowMoreFlyoutItem_Click(object sender, RoutedEventArgs e)
    {
        if (_moreFlyoutTrack is not TrackItem track || sender is not MenuFlyoutItem { Tag: string action })
        {
            return;
        }

        if (action == "edit")
        {
            await OpenEditDialogAsync(track);
        }
    }

    // ===== CommandBar actions =====

    private async void ScanFolderButton_Click(object sender, RoutedEventArgs e)
    {
        var picker = new FolderPicker
        {
            SuggestedStartLocation = PickerLocationId.MusicLibrary,
        };
        picker.FileTypeFilter.Add("*");

        // FolderPicker is a WinRT API that needs an owner HWND in a desktop
        // (non-UWP) app — there's no ambient window to infer it from.
        var hwnd = WindowNative.GetWindowHandle(App.MainAppWindow!);
        InitializeWithWindow.Initialize(picker, hwnd);

        var folder = await picker.PickSingleFolderAsync();
        if (folder is null)
        {
            return;
        }

        ScanFolderButton.IsEnabled = false;
        try
        {
            await ViewModel.ScanFolderAsync(folder.Path);
        }
        finally
        {
            ScanFolderButton.IsEnabled = true;
        }
    }

    private async Task OpenEditDialogAsync(TrackItem track)
    {
        // Pre-fill from the raw (un-fallback'd) values — Title/Artist/Album
        // on TrackItem carry placeholders like "Unknown Artist" that must
        // never get written into the file as if they were real tags.
        EditTitleBox.Text = track.RawTitle ?? string.Empty;
        EditArtistBox.Text = track.RawArtist ?? string.Empty;
        EditAlbumBox.Text = track.RawAlbum ?? string.Empty;
        EditTrackDialog.XamlRoot = XamlRoot;

        var result = await EditTrackDialog.ShowAsync();
        if (result != ContentDialogResult.Primary)
        {
            return;
        }

        await ViewModel.SaveTagEditAsync(track.Id, EditTitleBox.Text, EditArtistBox.Text, EditAlbumBox.Text);
    }

    private async void EditSelectedButton_Click(object sender, RoutedEventArgs e)
    {
        var selectedIds = TracksListView.SelectedItems
            .OfType<TrackItem>()
            .Select(t => t.Id)
            .ToList();

        if (selectedIds.Count == 0)
        {
            ViewModel.StatusMessage = "Select one or more tracks first.";
            return;
        }

        BatchArtistBox.Text = string.Empty;
        BatchAlbumBox.Text = string.Empty;
        BatchEditDialog.XamlRoot = XamlRoot;

        var result = await BatchEditDialog.ShowAsync();
        if (result != ContentDialogResult.Primary)
        {
            return;
        }

        await ViewModel.SaveBatchTagEditAsync(selectedIds, BatchArtistBox.Text, BatchAlbumBox.Text);
    }

    private async void RenameSelectedButton_Click(object sender, RoutedEventArgs e)
    {
        var selectedIds = TracksListView.SelectedItems
            .OfType<TrackItem>()
            .Select(t => t.Id)
            .ToList();

        if (selectedIds.Count == 0)
        {
            ViewModel.StatusMessage = "Select one or more tracks first.";
            return;
        }

        var picker = new FolderPicker
        {
            SuggestedStartLocation = PickerLocationId.MusicLibrary,
        };
        picker.FileTypeFilter.Add("*");
        var hwnd = WindowNative.GetWindowHandle(App.MainAppWindow!);
        InitializeWithWindow.Initialize(picker, hwnd);

        var folder = await picker.PickSingleFolderAsync();
        if (folder is null)
        {
            return;
        }

        RenamePatternDialog.XamlRoot = XamlRoot;
        var result = await RenamePatternDialog.ShowAsync();
        if (result != ContentDialogResult.Primary)
        {
            return;
        }

        await ViewModel.SaveRenameAsync(selectedIds, folder.Path, RenamePatternBox.Text);
    }

    private void SelectionCheckboxesToggle_Click(object sender, RoutedEventArgs e)
    {
        _showSelectionCheckboxes = SelectionCheckboxesToggle.IsChecked == true;
        SettingsViewModel.SaveShowTrackSelectionCheckboxes(_showSelectionCheckboxes);
        ApplySelectionMode();
    }

    // WinUI's ListView already shows native selection checkboxes in Multiple
    // mode and hides them otherwise — no custom checkbox column needed, this
    // is the native mechanism for exactly the toggle the user asked for.
    private void ApplySelectionMode()
    {
        TracksListView.SelectionMode = _showSelectionCheckboxes
            ? ListViewSelectionMode.Multiple
            : ListViewSelectionMode.Extended;
    }
}
