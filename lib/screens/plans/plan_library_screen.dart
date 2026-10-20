import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/plan_card.dart';
import 'plan_detail_screen.dart';

/// Browse built-in plans by category or search. Browsing is free.
class PlanLibraryScreen extends StatefulWidget {
  const PlanLibraryScreen({super.key});

  @override
  State<PlanLibraryScreen> createState() => _PlanLibraryScreenState();
}

class _PlanLibraryScreenState extends State<PlanLibraryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredPlans();

    return Scaffold(
      appBar: AppBar(title: const Text('Workout plans')),
      body: Column(
        children: [
          Padding(
            padding: context.pageGutter(top: 8, bottom: 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search plans',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.clear_rounded),
                      ),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          SizedBox(
            height: 48,
            child: _CategoryChips(
              selected: _selectedCategory,
              onSelected: (category) {
                setState(() => _selectedCategory = category);
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: results.isEmpty
                ? const EmptyState(
                    title: 'No matches',
                    message: 'Try another search or category.',
                    icon: Icons.search_off_rounded,
                  )
                : ListView.builder(
                    padding: context.pageGutter(bottom: 24),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final plan = results[index];
                      return PlanCard(plan: plan, onTap: () => _openPlan(plan));
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<WorkoutPlan> _filteredPlans() {
    var list = PlanLibrary.search(_query);
    final category = _selectedCategory;
    if (category != null) {
      list = list.where((plan) => plan.category == category).toList();
    }
    return list;
  }

  Future<void> _openPlan(WorkoutPlan plan) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => PlanDetailScreen(planId: plan.id)),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final categories = PlanLibrary.categories;
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FilterChip(
            label: const Text('All'),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
        ),
        for (final category in categories)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(category),
              selected: selected == category,
              onSelected: (_) {
                onSelected(selected == category ? null : category);
              },
            ),
          ),
      ],
    );
  }
}
