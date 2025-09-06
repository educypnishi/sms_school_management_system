import 'package:flutter/material.dart';
import '../models/program_comparison_model.dart';
import '../models/program_model.dart';
import '../theme/app_theme.dart';

/// A widget to display a comparison table for programs
class ProgramComparisonTable extends StatelessWidget {
  final ProgramComparisonModel comparison;
  final Function(String)? onRemoveCriterion;
  final Function(String)? onRemoveProgram;

  const ProgramComparisonTable({
    super.key,
    required this.comparison,
    this.onRemoveCriterion,
    this.onRemoveProgram,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        headingRowHeight: 60,
        dataRowMinHeight: 60,
        dataRowMaxHeight: 120,
        border: TableBorder.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        columns: _buildColumns(context),
        rows: _buildRows(context),
      ),
    );
  }

  List<DataColumn> _buildColumns(BuildContext context) {
    final columns = <DataColumn>[
      DataColumn(
        label: const Text(
          'Criteria',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    ];

    // Add a column for each program
    for (final program in comparison.programs) {
      columns.add(
        DataColumn(
          label: _buildProgramHeader(context, program),
        ),
      );
    }

    return columns;
  }

  Widget _buildProgramHeader(BuildContext context, ProgramModel program) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                program.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onRemoveProgram != null)
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () => onRemoveProgram!(program.id),
                tooltip: 'Remove from comparison',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 16,
              ),
          ],
        ),
        Text(
          program.university,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.lightTextColor,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  List<DataRow> _buildRows(BuildContext context) {
    final rows = <DataRow>[];

    // Add a row for each criterion
    for (final criterion in comparison.comparisonCriteria) {
      rows.add(
        DataRow(
          cells: _buildCellsForCriterion(context, criterion),
        ),
      );
    }

    return rows;
  }

  List<DataCell> _buildCellsForCriterion(BuildContext context, String criterion) {
    final cells = <DataCell>[
      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ProgramComparisonModel.getCriterionIcon(criterion),
              size: 16,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              ProgramComparisonModel.getCriterionDisplayName(criterion),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (onRemoveCriterion != null)
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () => onRemoveCriterion!(criterion),
                tooltip: 'Remove criterion',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 16,
              ),
          ],
        ),
      ),
    ];

    // Add a cell for each program
    for (final program in comparison.programs) {
      cells.add(
        DataCell(
          Text(
            comparison.getCriterionValue(criterion, program),
            style: const TextStyle(fontSize: 14),
          ),
        ),
      );
    }

    return cells;
  }
}
