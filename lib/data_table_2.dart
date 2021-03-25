library data_table_2;

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Copyright 2021 Maxim Saplin - chnages and modifications to original Flutter implementation of DataTable

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

const SM_ratio = 0.67;
const LM_ratio = 1.2;

enum ColumnSize { S, M, L }

/// Signature for [DataColumn2.onSort] callback.
// typedef DataColumnSortCallback = void Function(int columnIndex, bool ascending);

/// Column configuration for a [DataTable2].
///
/// One column configuration must be provided for each column to
/// display in the table. The list of [DataColumn2] objects is passed
/// as the `columns` argument to the [new DataTable] constructor.
@immutable
class DataColumn2 {
  /// Creates the configuration for a column of a [DataTable2].
  ///
  /// The [label] argument must not be null.
  const DataColumn2(
      {required this.label,
      this.tooltip,
      this.numeric = false,
      this.onSort,
      this.size = ColumnSize.M});

  /// The column heading.
  ///
  /// Typically, this will be a [Text] widget. It could also be an
  /// [Icon] (typically using size 18), or a [Row] with an icon and
  /// some text.
  ///
  /// By default, this widget will only occupy the minimal space. If you want
  /// it to take the entire remaining space, e.g. when you want to use [Center],
  /// you can wrap it with an [Expanded].
  ///
  /// The label should not include the sort indicator.
  final Widget label;

  /// The column heading's tooltip.
  ///
  /// This is a longer description of the column heading, for cases
  /// where the heading might have been abbreviated to keep the column
  /// width to a reasonable size.
  final String? tooltip;

  /// Whether this column represents numeric data or not.
  ///
  /// The contents of cells of columns containing numeric data are
  /// right-aligned.
  final bool numeric;

  /// Called when the user asks to sort the table using this column.
  ///
  /// If null, the column will not be considered sortable.
  ///
  /// See [DataTable2.sortColumnIndex] and [DataTable2.sortAscending].
  final DataColumnSortCallback? onSort;

  final ColumnSize size;

  // bool get _debugInteractive => onSort != null;
}

/// Row configuration and cell data for a [DataTable2].
///
/// One row configuration must be provided for each row to
/// display in the table. The list of [DataRow2] objects is passed
/// as the `rows` argument to the [new DataTable] constructor.
///
/// The data for this row of the table is provided in the [cells]
/// property of the [DataRow2] object.
@immutable
class DataRow2 {
  //DataRow2.fromDataRow(DataRow row) : this.cells = row.cells;

  /// Creates the configuration for a row of a [DataTable2].
  ///
  /// The [cells] argument must not be null.
  const DataRow2(
      {this.key,
      this.selected = false,
      this.onSelectChanged,
      this.color,
      required this.cells,
      this.onTap,
      this.onSecondaryTap,
      this.onSecondaryTapDown});

  /// Creates the configuration for a row of a [DataTable2], deriving
  /// the key from a row index.
  ///
  /// The [cells] argument must not be null.
  DataRow2.byIndex(
      {int? index,
      this.selected = false,
      this.onSelectChanged,
      this.color,
      required this.cells,
      this.onTap,
      this.onSecondaryTap,
      this.onSecondaryTapDown})
      : key = ValueKey<int?>(index);

  /// A [Key] that uniquely identifies this row. This is used to
  /// ensure that if a row is added or removed, any stateful widgets
  /// related to this row (e.g. an in-progress checkbox animation)
  /// remain on the right row visually.
  ///
  /// If the table never changes once created, no key is necessary.
  final LocalKey? key;

  /// Called when the user selects or unselects a selectable row.
  ///
  /// If this is not null, then the row is selectable. The current
  /// selection state of the row is given by [selected].
  ///
  /// If any row is selectable, then the table's heading row will have
  /// a checkbox that can be checked to select all selectable rows
  /// (and which is checked if all the rows are selected), and each
  /// subsequent row will have a checkbox to toggle just that row.
  ///
  /// A row whose [onSelectChanged] callback is null is ignored for
  /// the purposes of determining the state of the "all" checkbox,
  /// and its checkbox is disabled.
  ///
  /// If a [DataCell2] in the row has its [DataCell2.onTap] callback defined,
  /// that callback behavior overrides the gesture behavior of the row for
  /// that particular cell.
  final ValueChanged<bool?>? onSelectChanged;

  /// Whether the row is selected.
  ///
  /// If [onSelectChanged] is non-null for any row in the table, then
  /// a checkbox is shown at the start of each row. If the row is
  /// selected (true), the checkbox will be checked and the row will
  /// be highlighted.
  ///
  /// Otherwise, the checkbox, if present, will not be checked.
  final bool selected;

  /// The data for this row.
  ///
  /// There must be exactly as many cells as there are columns in the
  /// table.
  final List<DataCell> cells;

  /// The color for the row.
  ///
  /// By default, the color is transparent unless selected. Selected rows has
  /// a grey translucent color.
  ///
  /// The effective color can depend on the [MaterialState] state, if the
  /// row is selected, pressed, hovered, focused, disabled or enabled. The
  /// color is painted as an overlay to the row. To make sure that the row's
  /// [InkWell] is visible (when pressed, hovered and focused), it is
  /// recommended to use a translucent color.
  ///
  /// ```dart
  /// DataRow(
  ///   color: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
  ///     if (states.contains(MaterialState.selected))
  ///       return Theme.of(context).colorScheme.primary.withOpacity(0.08);
  ///     return null;  // Use the default value.
  ///   }),
  /// )
  /// ```
  ///
  /// See also:
  ///
  ///  * The Material Design specification for overlay colors and how they
  ///    match a component's state:
  ///    <https://material.io/design/interaction/states.html#anatomy>.
  final MaterialStateProperty<Color?>? color;

  final VoidCallback? onTap;
  final VoidCallback? onSecondaryTap;
  final GestureTapDownCallback? onSecondaryTapDown;

  // bool get _debugInteractive =>
  //     onSelectChanged != null ||
  //     cells.any((DataCell2 cell) => cell._debugInteractive);
}

/// A material design data table.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=ktTajqbhIcY}
///
/// Displaying data in a table is expensive, because to lay out the
/// table all the data must be measured twice, once to negotiate the
/// dimensions to use for each column, and once to actually lay out
/// the table given the results of the negotiation.
///
/// For this reason, if you have a lot of data (say, more than a dozen
/// rows with a dozen columns, though the precise limits depend on the
/// target device), it is suggested that you use a
/// [PaginatedDataTable] which automatically splits the data into
/// multiple pages.
///
/// {@tool dartpad --template=stateless_widget_scaffold}
///
/// This sample shows how to display a [DataTable2] with three columns: name, age, and
/// role. The columns are defined by three [DataColumn2] objects. The table
/// contains three rows of data for three example users, the data for which
/// is defined by three [DataRow2] objects.
///
/// ![](https://flutter.github.io/assets-for-api-docs/assets/material/data_table.png)
///
/// ```dart
/// Widget build(BuildContext context) {
///   return DataTable(
///     columns: const <DataColumn>[
///       DataColumn(
///         label: Text(
///           'Name',
///           style: TextStyle(fontStyle: FontStyle.italic),
///         ),
///       ),
///       DataColumn(
///         label: Text(
///           'Age',
///           style: TextStyle(fontStyle: FontStyle.italic),
///         ),
///       ),
///       DataColumn(
///         label: Text(
///           'Role',
///           style: TextStyle(fontStyle: FontStyle.italic),
///         ),
///       ),
///     ],
///     rows: const <DataRow>[
///       DataRow(
///         cells: <DataCell>[
///           DataCell(Text('Sarah')),
///           DataCell(Text('19')),
///           DataCell(Text('Student')),
///         ],
///       ),
///       DataRow(
///         cells: <DataCell>[
///           DataCell(Text('Janine')),
///           DataCell(Text('43')),
///           DataCell(Text('Professor')),
///         ],
///       ),
///       DataRow(
///         cells: <DataCell>[
///           DataCell(Text('William')),
///           DataCell(Text('27')),
///           DataCell(Text('Associate Professor')),
///         ],
///       ),
///     ],
///   );
/// }
/// ```
///
/// {@end-tool}
///
///
/// {@tool dartpad --template=stateful_widget_scaffold}
///
/// This sample shows how to display a [DataTable2] with alternate colors per
/// row, and a custom color for when the row is selected.
///
/// ```dart
/// static const int numItems = 10;
/// List<bool> selected = List<bool>.generate(numItems, (index) => false);
///
/// @override
/// Widget build(BuildContext context) {
///   return SizedBox(
///     width: double.infinity,
///     child: DataTable(
///       columns: const <DataColumn>[
///         DataColumn(
///           label: const Text('Number'),
///         ),
///       ],
///       rows: List<DataRow>.generate(
///         numItems,
///         (index) => DataRow(
///           color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
///             // All rows will have the same selected color.
///             if (states.contains(MaterialState.selected))
///               return Theme.of(context).colorScheme.primary.withOpacity(0.08);
///             // Even rows will have a grey color.
///             if (index % 2 == 0)
///               return Colors.grey.withOpacity(0.3);
///             return null;  // Use default value for other states and odd rows.
///           }),
///           cells: [DataCell(Text('Row $index'))],
///           selected: selected[index],
///           onSelectChanged: (bool? value) {
///             setState(() {
///               selected[index] = value!;
///             });
///           },
///         ),
///       ),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// [DataTable2] can be sorted on the basis of any column in [columns] in
/// ascending or descending order. If [sortColumnIndex] is non-null, then the
/// table will be sorted by the values in the specified column. The boolean
/// [sortAscending] flag controls the sort order.
///
/// See also:
///
///  * [DataColumn2], which describes a column in the data table.
///  * [DataRow2], which contains the data for a row in the data table.
///  * [DataCell2], which contains the data for a single cell in the data table.
///  * [PaginatedDataTable], which shows part of the data in a data table and
///    provides controls for paging through the remainder of the data.
///  * <https://material.io/design/components/data-tables.html>
class DataTable2 extends StatelessWidget {
  /// Creates a widget describing a data table.
  ///
  /// The [columns] argument must be a list of as many [DataColumn2]
  /// objects as the table is to have columns, ignoring the leading
  /// checkbox column if any. The [columns] argument must have a
  /// length greater than zero and must not be null.
  ///
  /// The [rows] argument must be a list of as many [DataRow2] objects
  /// as the table is to have rows, ignoring the leading heading row
  /// that contains the column headings (derived from the [columns]
  /// argument). There may be zero rows, but the rows argument must
  /// not be null.
  ///
  /// Each [DataRow2] object in [rows] must have as many [DataCell2]
  /// objects in the [DataRow2.cells] list as the table has columns.
  ///
  /// If the table is sorted, the column that provides the current
  /// primary key should be specified by index in [sortColumnIndex], 0
  /// meaning the first column in [columns], 1 being the next one, and
  /// so forth.
  ///
  /// The actual sort order can be specified using [sortAscending]; if
  /// the sort order is ascending, this should be true (the default),
  /// otherwise it should be false.
  DataTable2({
    Key? key,
    required this.columns,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSelectAll,
    this.decoration,
    this.dataRowColor,
    this.dataRowHeight,
    this.dataTextStyle,
    this.headingRowColor,
    this.headingRowHeight,
    this.headingTextStyle,
    this.horizontalMargin,
    this.columnSpacing,
    this.showCheckboxColumn = true,
    this.showBottomBorder = false,
    this.dividerThickness,
    required this.rows,
  })   : assert(columns.isNotEmpty),
        assert(sortColumnIndex == null ||
            (sortColumnIndex >= 0 && sortColumnIndex < columns.length)),
        assert(!rows.any((DataRow2 row) => row.cells.length != columns.length)),
        assert(dividerThickness == null || dividerThickness >= 0),
        super(key: key);

  /// The configuration and labels for the columns in the table.
  final List<DataColumn2> columns;

  /// The current primary sort key's column.
  ///
  /// If non-null, indicates that the indicated column is the column
  /// by which the data is sorted. The number must correspond to the
  /// index of the relevant column in [columns].
  ///
  /// Setting this will cause the relevant column to have a sort
  /// indicator displayed.
  ///
  /// When this is null, it implies that the table's sort order does
  /// not correspond to any of the columns.
  final int? sortColumnIndex;

  /// Whether the column mentioned in [sortColumnIndex], if any, is sorted
  /// in ascending order.
  ///
  /// If true, the order is ascending (meaning the rows with the
  /// smallest values for the current sort column are first in the
  /// table).
  ///
  /// If false, the order is descending (meaning the rows with the
  /// smallest values for the current sort column are last in the
  /// table).
  final bool sortAscending;

  /// Invoked when the user selects or unselects every row, using the
  /// checkbox in the heading row.
  ///
  /// If this is null, then the [DataRow2.onSelectChanged] callback of
  /// every row in the table is invoked appropriately instead.
  ///
  /// To control whether a particular row is selectable or not, see
  /// [DataRow2.onSelectChanged]. This callback is only relevant if any
  /// row is selectable.
  final ValueSetter<bool?>? onSelectAll;

  /// {@template flutter.material.dataTable.decoration}
  /// The background and border decoration for the table.
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.decoration] is used. By default there is no
  /// decoration.
  final Decoration? decoration;

  /// {@template flutter.material.dataTable.dataRowColor}
  /// The background color for the data rows.
  ///
  /// The effective background color can be made to depend on the
  /// [MaterialState] state, i.e. if the row is selected, pressed, hovered,
  /// focused, disabled or enabled. The color is painted as an overlay to the
  /// row. To make sure that the row's [InkWell] is visible (when pressed,
  /// hovered and focused), it is recommended to use a translucent background
  /// color.
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.dataRowColor] is used. By default, the
  /// background color is transparent unless selected. Selected rows have a grey
  /// translucent color. To set a different color for individual rows, see
  /// [DataRow2.color].
  ///
  /// {@template flutter.material.DataTable.dataRowColor}
  /// ```dart
  /// DataTable(
  ///   dataRowColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
  ///     if (states.contains(MaterialState.selected))
  ///       return Theme.of(context).colorScheme.primary.withOpacity(0.08);
  ///     return null;  // Use the default value.
  ///   }),
  /// )
  /// ```
  ///
  /// See also:
  ///
  ///  * The Material Design specification for overlay colors and how they
  ///    match a component's state:
  ///    <https://material.io/design/interaction/states.html#anatomy>.
  /// {@endtemplate}
  final MaterialStateProperty<Color?>? dataRowColor;

  /// {@template flutter.material.dataTable.dataRowHeight}
  /// The height of each row (excluding the row that contains column headings).
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.dataRowHeight] is used. This value defaults
  /// to [kMinInteractiveDimension] to adhere to the Material Design
  /// specifications.
  final double? dataRowHeight;

  /// {@template flutter.material.dataTable.dataTextStyle}
  /// The text style for data rows.
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.dataTextStyle] is used. By default, the text
  /// style is [TextTheme.bodyText2].
  final TextStyle? dataTextStyle;

  /// {@template flutter.material.dataTable.headingRowColor}
  /// The background color for the heading row.
  ///
  /// The effective background color can be made to depend on the
  /// [MaterialState] state, i.e. if the row is pressed, hovered, focused when
  /// sorted. The color is painted as an overlay to the row. To make sure that
  /// the row's [InkWell] is visible (when pressed, hovered and focused), it is
  /// recommended to use a translucent color.
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.headingRowColor] is used.
  ///
  /// {@template flutter.material.DataTable.headingRowColor}
  /// ```dart
  /// DataTable(
  ///   headingRowColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
  ///     if (states.contains(MaterialState.hovered))
  ///       return Theme.of(context).colorScheme.primary.withOpacity(0.08);
  ///     return null;  // Use the default value.
  ///   }),
  /// )
  /// ```
  ///
  /// See also:
  ///
  ///  * The Material Design specification for overlay colors and how they
  ///    match a component's state:
  ///    <https://material.io/design/interaction/states.html#anatomy>.
  /// {@endtemplate}
  final MaterialStateProperty<Color?>? headingRowColor;

  /// {@template flutter.material.dataTable.headingRowHeight}
  /// The height of the heading row.
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.headingRowHeight] is used. This value
  /// defaults to 56.0 to adhere to the Material Design specifications.
  final double? headingRowHeight;

  /// {@template flutter.material.dataTable.headingTextStyle}
  /// The text style for the heading row.
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.headingTextStyle] is used. By default, the
  /// text style is [TextTheme.subtitle2].
  final TextStyle? headingTextStyle;

  /// {@template flutter.material.dataTable.horizontalMargin}
  /// The horizontal margin between the edges of the table and the content
  /// in the first and last cells of each row.
  ///
  /// When a checkbox is displayed, it is also the margin between the checkbox
  /// the content in the first data column.
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.horizontalMargin] is used. This value
  /// defaults to 24.0 to adhere to the Material Design specifications.
  final double? horizontalMargin;

  /// {@template flutter.material.dataTable.columnSpacing}
  /// The horizontal margin between the contents of each data column.
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.columnSpacing] is used. This value defaults
  /// to 56.0 to adhere to the Material Design specifications.
  final double? columnSpacing;

  /// {@template flutter.material.dataTable.showCheckboxColumn}
  /// Whether the widget should display checkboxes for selectable rows.
  ///
  /// If true, a [Checkbox] will be placed at the beginning of each row that is
  /// selectable. However, if [DataRow2.onSelectChanged] is not set for any row,
  /// checkboxes will not be placed, even if this value is true.
  ///
  /// If false, all rows will not display a [Checkbox].
  /// {@endtemplate}
  final bool showCheckboxColumn;

  /// The data to show in each row (excluding the row that contains
  /// the column headings).
  ///
  /// Must be non-null, but may be empty.
  final List<DataRow2> rows;

  /// {@template flutter.material.dataTable.dividerThickness}
  /// The width of the divider that appears between [TableRow]s.
  ///
  /// Must be greater than or equal to zero.
  /// {@endtemplate}
  ///
  /// If null, [DataTableThemeData.dividerThickness] is used. This value
  /// defaults to 1.0.
  final double? dividerThickness;

  /// Whether a border at the bottom of the table is displayed.
  ///
  /// By default, a border is not shown at the bottom to allow for a border
  /// around the table defined by [decoration].
  final bool showBottomBorder;

  // bool get _debugInteractive {
  //   return columns.any((DataColumn2 column) => column._debugInteractive) ||
  //       rows.any((DataRow2 row) => row._debugInteractive);
  // }

  static final LocalKey _headingRowKey = UniqueKey();

  void _handleSelectAll(bool? checked, bool someChecked) {
    // If some checkboxes are checked, all checkboxes are selected. Otherwise,
    // use the new checked value but default to false if it's null.
    final bool effectiveChecked = someChecked || (checked ?? false);
    if (onSelectAll != null) {
      onSelectAll!(effectiveChecked);
    } else {
      for (final DataRow2 row in rows) {
        if (row.onSelectChanged != null && row.selected != effectiveChecked)
          row.onSelectChanged!(effectiveChecked);
      }
    }
  }

  /// The default height of the heading row.
  static const double _headingRowHeight = 56.0;

  /// The default horizontal margin between the edges of the table and the content
  /// in the first and last cells of each row.
  static const double _horizontalMargin = 24.0;

  /// The default horizontal margin between the contents of each data column.
  static const double _columnSpacing = 56.0;

  /// The default padding between the heading content and sort arrow.
  static const double _sortArrowPadding = 2.0;

  /// The default divider thickness.
  static const double _dividerThickness = 1.0;

  static const Duration _sortArrowAnimationDuration =
      Duration(milliseconds: 150);

  Widget _buildCheckbox({
    required BuildContext context,
    required bool? checked,
    required VoidCallback? onRowTap,
    required ValueChanged<bool?>? onCheckboxChanged,
    required MaterialStateProperty<Color?>? overlayColor,
    required bool tristate,
  }) {
    final ThemeData themeData = Theme.of(context);
    final double effectiveHorizontalMargin = horizontalMargin ??
        themeData.dataTableTheme.horizontalMargin ??
        _horizontalMargin;
    Widget contents = Semantics(
      container: true,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: effectiveHorizontalMargin,
          end: effectiveHorizontalMargin / 2.0,
        ),
        child: Center(
          child: Checkbox(
            activeColor: themeData.colorScheme.primary,
            checkColor: themeData.colorScheme.onPrimary,
            value: checked,
            onChanged: onCheckboxChanged,
            tristate: tristate,
          ),
        ),
      ),
    );
    if (onRowTap != null) {
      contents = TableRowInkWell(
        onTap: onRowTap,
        child: contents,
        overlayColor: overlayColor,
      );
    }
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.fill,
      child: contents,
    );
  }

  Widget _buildHeadingCell({
    required BuildContext context,
    required EdgeInsetsGeometry padding,
    required Widget label,
    required String? tooltip,
    required bool numeric,
    required VoidCallback? onSort,
    required bool sorted,
    required bool ascending,
    required MaterialStateProperty<Color?>? overlayColor,
  }) {
    final ThemeData themeData = Theme.of(context);
    label = Row(
      textDirection: numeric ? TextDirection.rtl : null,
      children: <Widget>[
        Flexible(child: label),
        if (onSort != null) ...<Widget>[
          _SortArrow(
            visible: sorted,
            up: sorted ? ascending : null,
            duration: _sortArrowAnimationDuration,
          ),
          const SizedBox(width: _sortArrowPadding),
        ],
      ],
    );

    final TextStyle effectiveHeadingTextStyle = headingTextStyle ??
        themeData.dataTableTheme.headingTextStyle ??
        themeData.textTheme.subtitle2!;
    final double effectiveHeadingRowHeight = headingRowHeight ??
        themeData.dataTableTheme.headingRowHeight ??
        _headingRowHeight;
    label = Container(
      padding: padding,
      height: effectiveHeadingRowHeight,
      alignment:
          numeric ? Alignment.centerRight : AlignmentDirectional.centerStart,
      child: AnimatedDefaultTextStyle(
        style: effectiveHeadingTextStyle,
        softWrap: false,
        duration: _sortArrowAnimationDuration,
        child: label,
      ),
    );
    if (tooltip != null) {
      label = Tooltip(
        message: tooltip,
        child: label,
      );
    }

    label = InkWell(
      onTap: onSort,
      overlayColor: overlayColor,
      child: label,
    );
    return label;
  }

  Widget _buildDataCell({
    required BuildContext context,
    required EdgeInsetsGeometry padding,
    required Widget label,
    required bool numeric,
    required bool placeholder,
    required bool showEditIcon,
    required VoidCallback? onTap,
    required VoidCallback? onRowTap,
    required VoidCallback? onRowSecondaryTap,
    required GestureTapDownCallback? onRowSecondaryTapDown,
    required VoidCallback? onSelectChanged,
    required MaterialStateProperty<Color?>? overlayColor,
  }) {
    final ThemeData themeData = Theme.of(context);
    if (showEditIcon) {
      const Widget icon = Icon(Icons.edit, size: 18.0);
      label = Expanded(child: label);
      label = Row(
        textDirection: numeric ? TextDirection.rtl : null,
        children: <Widget>[label, icon],
      );
    }

    final TextStyle effectiveDataTextStyle = dataTextStyle ??
        themeData.dataTableTheme.dataTextStyle ??
        themeData.textTheme.bodyText2!;
    final double effectiveDataRowHeight = dataRowHeight ??
        themeData.dataTableTheme.dataRowHeight ??
        kMinInteractiveDimension;
    label = Container(
      padding: padding,
      height: effectiveDataRowHeight,
      alignment:
          numeric ? Alignment.centerRight : AlignmentDirectional.centerStart,
      child: DefaultTextStyle(
        style: effectiveDataTextStyle.copyWith(
          color: placeholder
              ? effectiveDataTextStyle.color!.withOpacity(0.6)
              : null,
        ),
        child: DropdownButtonHideUnderline(child: label),
      ),
    );
    if (onTap != null) {
      label = InkWell(
        onTap: onTap,
        child: label,
        overlayColor: overlayColor,
      );
    } else if (onSelectChanged != null) {
      label = GestureDetector(
        child: TableRowInkWell(
            child: label,
            overlayColor: overlayColor,
            onTap: onRowTap == null
                ? onSelectChanged
                : () {
                    onRowTap();
                    onSelectChanged();
                  }),
        onSecondaryTap: onRowSecondaryTap,
        onSecondaryTapDown: onRowSecondaryTapDown,
      );
    }
    return label;
  }

  @override
  Widget build(BuildContext context) {
    var sw = Stopwatch();
    sw.start();
    // assert(!_debugInteractive || debugCheckHasMaterial(context));
    assert(debugCheckHasMaterial(context));

    final ThemeData theme = Theme.of(context);
    final MaterialStateProperty<Color?>? effectiveHeadingRowColor =
        headingRowColor ?? theme.dataTableTheme.headingRowColor;
    final MaterialStateProperty<Color?>? effectiveDataRowColor =
        dataRowColor ?? theme.dataTableTheme.dataRowColor;
    final MaterialStateProperty<Color?> defaultRowColor =
        MaterialStateProperty.resolveWith(
      (Set<MaterialState> states) {
        if (states.contains(MaterialState.selected))
          return theme.colorScheme.primary.withOpacity(0.08);
        return null;
      },
    );
    final bool anyRowSelectable =
        rows.any((DataRow2 row) => row.onSelectChanged != null);
    final bool displayCheckboxColumn = showCheckboxColumn && anyRowSelectable;
    final Iterable<DataRow2> rowsWithCheckbox = displayCheckboxColumn
        ? rows.where((DataRow2 row) => row.onSelectChanged != null)
        : <DataRow2>[];
    final Iterable<DataRow2> rowsChecked =
        rowsWithCheckbox.where((DataRow2 row) => row.selected);
    final bool allChecked =
        displayCheckboxColumn && rowsChecked.length == rowsWithCheckbox.length;
    final bool anyChecked = displayCheckboxColumn && rowsChecked.isNotEmpty;
    final bool someChecked = anyChecked && !allChecked;
    final double effectiveHorizontalMargin = horizontalMargin ??
        theme.dataTableTheme.horizontalMargin ??
        _horizontalMargin;
    final double effectiveColumnSpacing =
        columnSpacing ?? theme.dataTableTheme.columnSpacing ?? _columnSpacing;

    final List<TableColumnWidth> tableColumns = List<TableColumnWidth>.filled(
        columns.length + (displayCheckboxColumn ? 1 : 0),
        const _NullTableColumnWidth());
    final List<TableRow> tableRows = List<TableRow>.generate(
      rows.length + 1, // the +1 is for the header row
      (int index) {
        final bool isSelected = index > 0 && rows[index - 1].selected;
        final bool isDisabled = index > 0 &&
            anyRowSelectable &&
            rows[index - 1].onSelectChanged == null;
        final Set<MaterialState> states = <MaterialState>{
          if (isSelected) MaterialState.selected,
          if (isDisabled) MaterialState.disabled,
        };
        final Color? resolvedDataRowColor = index > 0
            ? (rows[index - 1].color ?? effectiveDataRowColor)?.resolve(states)
            : null;
        final Color? resolvedHeadingRowColor =
            effectiveHeadingRowColor?.resolve(<MaterialState>{});
        final Color? rowColor =
            index > 0 ? resolvedDataRowColor : resolvedHeadingRowColor;
        final BorderSide borderSide = Divider.createBorderSide(
          context,
          width: dividerThickness ??
              theme.dataTableTheme.dividerThickness ??
              _dividerThickness,
        );
        final Border? border = showBottomBorder
            ? Border(bottom: borderSide)
            : index == 0
                ? null
                : Border(top: borderSide);
        return TableRow(
          key: index == 0 ? _headingRowKey : rows[index - 1].key,
          decoration: BoxDecoration(
            border: border,
            color: rowColor ?? defaultRowColor.resolve(states),
          ),
          children:
              List<Widget>.filled(tableColumns.length, const _NullWidget()),
        );
      },
    );

    var builder = LayoutBuilder(builder: (context, constraints) {
      int rowIndex;

      int displayColumnIndex = 0;
      double checkBoxWidth = 0;
      if (displayCheckboxColumn) {
        checkBoxWidth = effectiveHorizontalMargin +
            Checkbox.width +
            effectiveHorizontalMargin / 2.0;
        tableColumns[0] = FixedColumnWidth(checkBoxWidth);
        tableRows[0].children![0] = _buildCheckbox(
          context: context,
          checked: someChecked ? null : allChecked,
          onRowTap: null,
          onCheckboxChanged: (bool? checked) =>
              _handleSelectAll(checked, someChecked),
          overlayColor: null,
          tristate: true,
        );
        rowIndex = 1;
        for (final DataRow2 row in rows) {
          tableRows[rowIndex].children![0] = _buildCheckbox(
            context: context,
            checked: row.selected,
            onRowTap: () => row.onSelectChanged != null
                ? row.onSelectChanged!(!row.selected)
                : null,
            onCheckboxChanged: row.onSelectChanged,
            overlayColor: row.color ?? effectiveDataRowColor,
            tristate: false,
          );
          rowIndex += 1;
        }
        displayColumnIndex += 1;
      }

      // var availableWidth = MediaQuery.of(context).size.width - checkBoxWidth;
      // var d = MediaQuery.of(context);
      var availableWidth = constraints.maxWidth - checkBoxWidth;
      var columnWidth = availableWidth / columns.length;
      var totalWidth = 0.0;

      var widths = List<double>.generate(columns.length, (i) {
        var w = columnWidth;
        if (columns[i].size == ColumnSize.S) {
          w *= SM_ratio;
        } else if (columns[i].size == ColumnSize.L) {
          w *= LM_ratio;
        }
        totalWidth += w;
        return w;
      });

      var ratio = availableWidth / totalWidth;

      for (var i = 0; i < widths.length; i++) {
        widths[i] *= ratio;
      }

      for (int dataColumnIndex = 0;
          dataColumnIndex < columns.length;
          dataColumnIndex += 1) {
        final DataColumn2 column = columns[dataColumnIndex];

        final double paddingStart;
        if (dataColumnIndex == 0 && displayCheckboxColumn) {
          paddingStart = effectiveHorizontalMargin / 2.0;
        } else if (dataColumnIndex == 0 && !displayCheckboxColumn) {
          paddingStart = effectiveHorizontalMargin;
        } else {
          paddingStart = effectiveColumnSpacing / 2.0;
        }

        final double paddingEnd;
        if (dataColumnIndex == columns.length - 1) {
          paddingEnd = effectiveHorizontalMargin;
        } else {
          paddingEnd = effectiveColumnSpacing / 2.0;
        }

        final EdgeInsetsDirectional padding = EdgeInsetsDirectional.only(
          start: paddingStart,
          end: paddingEnd,
        );

        tableColumns[displayColumnIndex] = //const IntrinsicColumnWidth();
            FixedColumnWidth(widths[dataColumnIndex]);

        // if (dataColumnIndex == _onlyTextColumn) {
        //   tableColumns[displayColumnIndex] =
        //       const IntrinsicColumnWidth(flex: 1.0);
        // } else {
        //   tableColumns[displayColumnIndex] = const IntrinsicColumnWidth();
        // }
        tableRows[0].children![displayColumnIndex] = _buildHeadingCell(
          context: context,
          padding: padding,
          label: column.label,
          tooltip: column.tooltip,
          numeric: column.numeric,
          onSort: column.onSort != null
              ? () => column.onSort!(dataColumnIndex,
                  sortColumnIndex != dataColumnIndex || !sortAscending)
              : null,
          sorted: dataColumnIndex == sortColumnIndex,
          ascending: sortAscending,
          overlayColor: effectiveHeadingRowColor,
        );
        rowIndex = 1;
        for (final DataRow2 row in rows) {
          final DataCell cell = row.cells[dataColumnIndex];
          tableRows[rowIndex].children![displayColumnIndex] = _buildDataCell(
            context: context,
            padding: padding,
            label: cell.child,
            numeric: column.numeric,
            placeholder: cell.placeholder,
            showEditIcon: cell.showEditIcon,
            onTap: cell.onTap,
            onRowTap: row.onTap,
            onRowSecondaryTap: row.onSecondaryTap,
            onRowSecondaryTapDown: row.onSecondaryTapDown,
            onSelectChanged: () => row.onSelectChanged != null
                ? row.onSelectChanged!(!row.selected)
                : null,
            overlayColor: row.color ?? effectiveDataRowColor,
          );
          rowIndex += 1;
        }
        displayColumnIndex += 1;
      }

      var widthsAsMap = tableColumns.asMap();

      var w = Container(
          decoration: decoration ?? theme.dataTableTheme.decoration,
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Table(
                  columnWidths: widthsAsMap,
                  children: [
                    tableRows[0]
                  ], // TODO - generate above 2 lists right away
                ),
                Flexible(
                    fit: FlexFit.loose,
                    child: SingleChildScrollView(
                        child: Table(
                      columnWidths: widthsAsMap,
                      children:
                          tableRows.skip(1).take(tableRows.length - 1).toList(),
                    )))
              ],
            ),
          ));

      return w;
    });

    sw.stop();
    print('DataTable2 built: ${sw.elapsedMilliseconds}ms');
    return builder;
  }
}

/// A rectangular area of a Material that responds to touch but clips
/// its ink splashes to the current table row of the nearest table.
///
/// Must have an ancestor [Material] widget in which to cause ink
/// reactions and an ancestor [Table] widget to establish a row.
///
/// The [TableRowInkWell] must be in the same coordinate space (modulo
/// translations) as the [Table]. If it's rotated or scaled or
/// otherwise transformed, it will not be able to describe the
/// rectangle of the row in its own coordinate system as a [Rect], and
/// thus the splash will not occur. (In general, this is easy to
/// achieve: just put the [TableRowInkWell] as the direct child of the
/// [Table], and put the other contents of the cell inside it.)
///
/// See also:
///
///  * [DataTable2], which makes use of [TableRowInkWell] when
///    [DataRow.onSelectChanged] is defined and [DataCell.onTap]
///    is not.
// class TableRowInkWell extends InkResponse {
//   /// Creates an ink well for a table row.
//   const TableRowInkWell({
//     Key? key,
//     Widget? child,
//     GestureTapCallback? onTap,
//     GestureTapCallback? onDoubleTap,
//     GestureLongPressCallback? onLongPress,
//     ValueChanged<bool>? onHighlightChanged,
//     MaterialStateProperty<Color?>? overlayColor,
//   }) : super(
//           key: key,
//           child: child,
//           onTap: onTap,
//           onDoubleTap: onDoubleTap,
//           onLongPress: onLongPress,
//           onHighlightChanged: onHighlightChanged,
//           containedInkWell: true,
//           highlightShape: BoxShape.rectangle,
//           overlayColor: overlayColor,
//         );

//   @override
//   RectCallback getRectCallback(RenderBox referenceBox) {
//     return () {
//       RenderObject cell = referenceBox;
//       AbstractNode? table = cell.parent;
//       final Matrix4 transform = Matrix4.identity();
//       while (table is RenderObject && table is! RenderTable) {
//         table.applyPaintTransform(cell, transform);
//         assert(table == cell.parent);
//         cell = table;
//         table = table.parent;
//       }
//       if (table is RenderTable) {
//         final TableCellParentData cellParentData =
//             cell.parentData! as TableCellParentData;
//         assert(cellParentData.y != null);
//         final Rect rect = table.getRowBox(cellParentData.y!);
//         // The rect is in the table's coordinate space. We need to change it to the
//         // TableRowInkWell's coordinate space.
//         table.applyPaintTransform(cell, transform);
//         final Offset? offset = MatrixUtils.getAsTranslation(transform);
//         if (offset != null) return rect.shift(-offset);
//       }
//       return Rect.zero;
//     };
//   }

//   @override
//   bool debugCheckContext(BuildContext context) {
//     assert(debugCheckHasTable(context));
//     return super.debugCheckContext(context);
//   }
// }

class _SortArrow extends StatefulWidget {
  const _SortArrow({
    Key? key,
    required this.visible,
    required this.up,
    required this.duration,
  }) : super(key: key);

  final bool visible;

  final bool? up;

  final Duration duration;

  @override
  _SortArrowState createState() => _SortArrowState();
}

class _SortArrowState extends State<_SortArrow> with TickerProviderStateMixin {
  late AnimationController _opacityController;
  late Animation<double> _opacityAnimation;

  late AnimationController _orientationController;
  late Animation<double> _orientationAnimation;
  double _orientationOffset = 0.0;

  bool? _up;

  static final Animatable<double> _turnTween =
      Tween<double>(begin: 0.0, end: math.pi)
          .chain(CurveTween(curve: Curves.easeIn));

  @override
  void initState() {
    super.initState();
    _opacityAnimation = CurvedAnimation(
      parent: _opacityController = AnimationController(
        duration: widget.duration,
        vsync: this,
      ),
      curve: Curves.fastOutSlowIn,
    )..addListener(_rebuild);
    _opacityController.value = widget.visible ? 1.0 : 0.0;
    _orientationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _orientationAnimation = _orientationController.drive(_turnTween)
      ..addListener(_rebuild)
      ..addStatusListener(_resetOrientationAnimation);
    if (widget.visible) _orientationOffset = widget.up! ? 0.0 : math.pi;
  }

  void _rebuild() {
    setState(() {
      // The animations changed, so we need to rebuild.
    });
  }

  void _resetOrientationAnimation(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      assert(_orientationAnimation.value == math.pi);
      _orientationOffset += math.pi;
      _orientationController.value =
          0.0; // TODO(ianh): This triggers a pointless rebuild.
    }
  }

  @override
  void didUpdateWidget(_SortArrow oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool skipArrow = false;
    final bool? newUp = widget.up ?? _up;
    if (oldWidget.visible != widget.visible) {
      if (widget.visible &&
          (_opacityController.status == AnimationStatus.dismissed)) {
        _orientationController.stop();
        _orientationController.value = 0.0;
        _orientationOffset = newUp! ? 0.0 : math.pi;
        skipArrow = true;
      }
      if (widget.visible) {
        _opacityController.forward();
      } else {
        _opacityController.reverse();
      }
    }
    if ((_up != newUp) && !skipArrow) {
      if (_orientationController.status == AnimationStatus.dismissed) {
        _orientationController.forward();
      } else {
        _orientationController.reverse();
      }
    }
    _up = newUp;
  }

  @override
  void dispose() {
    _opacityController.dispose();
    _orientationController.dispose();
    super.dispose();
  }

  static const double _arrowIconBaselineOffset = -1.5;
  static const double _arrowIconSize = 16.0;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _opacityAnimation.value,
      child: Transform(
        transform:
            Matrix4.rotationZ(_orientationOffset + _orientationAnimation.value)
              ..setTranslationRaw(0.0, _arrowIconBaselineOffset, 0.0),
        alignment: Alignment.center,
        child: const Icon(
          Icons.arrow_upward,
          size: _arrowIconSize,
        ),
      ),
    );
  }
}

class _NullTableColumnWidth extends TableColumnWidth {
  const _NullTableColumnWidth();

  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) =>
      throw UnimplementedError();

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) =>
      throw UnimplementedError();
}

class _NullWidget extends Widget {
  const _NullWidget();

  @override
  Element createElement() => throw UnimplementedError();
}
