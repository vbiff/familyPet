import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FamilyList extends ConsumerWidget {
  const FamilyList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Replace with actual family members from provider
    final familyMembers = [
      {
        'name': 'Mom',
        'role': 'Parent',
        'avatar': Icons.woman,
        'status': 'Online',
        'tasks': 8,
        'points': 150,
      },
      {
        'name': 'Dad',
        'role': 'Parent',
        'avatar': Icons.man,
        'status': 'Away',
        'tasks': 6,
        'points': 120,
      },
      {
        'name': 'Alex',
        'role': 'Child',
        'avatar': Icons.child_care,
        'status': 'Online',
        'tasks': 12,
        'points': 240,
      },
      {
        'name': 'Emma',
        'role': 'Child',
        'avatar': Icons.girl,
        'status': 'Online',
        'tasks': 15,
        'points': 300,
      },
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Family overview card
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.home,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'The Smith Family',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              '${familyMembers.length} members • Created 6 months ago',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                        .withValues(alpha: 0.8),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFamilyStat(
                          context,
                          'Total Points',
                          '810',
                          Icons.stars,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildFamilyStat(
                          context,
                          'Tasks Done',
                          '41',
                          Icons.task_alt,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Family Members',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Family members list
          ...familyMembers.map((member) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: member['role'] == 'Parent'
                                  ? [
                                      Theme.of(context).colorScheme.primary,
                                      Theme.of(context).colorScheme.secondary,
                                    ]
                                  : [
                                      Theme.of(context).colorScheme.tertiary,
                                      Theme.of(context).colorScheme.secondary,
                                    ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            member['avatar'] as IconData,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Member info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    member['name'] as String,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: member['status'] == 'Online'
                                          ? Colors.green
                                          : Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                member['role'] as String,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildMemberStat(
                                    context,
                                    Icons.assignment,
                                    '${member['tasks']} tasks',
                                  ),
                                  const SizedBox(width: 16),
                                  _buildMemberStat(
                                    context,
                                    Icons.stars,
                                    '${member['points']} pts',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Actions
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          onSelected: (value) {
                            // TODO: Implement member actions
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('$value for ${member['name']}')),
                            );
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'View Profile',
                              child: Text('View Profile'),
                            ),
                            const PopupMenuItem(
                              value: 'Send Message',
                              child: Text('Send Message'),
                            ),
                            const PopupMenuItem(
                              value: 'Assign Task',
                              child: Text('Assign Task'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )),

          const SizedBox(height: 24),

          // Add member button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                // TODO: Implement add family member
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Add family member coming soon!')),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Invite Family Member'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          size: 20,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer
                        .withValues(alpha: 0.8),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMemberStat(
    BuildContext context,
    IconData icon,
    String text,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
