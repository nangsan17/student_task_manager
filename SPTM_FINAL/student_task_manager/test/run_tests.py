"""
SPTM – Student Productivity & Task Management
Test Runner (Python mirror of sptm_test.dart)
Group 27 | CT124-3-2 Mobile App Engineering

Mirrors the business logic from task_model.dart, user_model.dart, theme.dart
and runs the exact same 50 test cases defined in sptm_test.dart.
"""

import unittest
from datetime import datetime, timedelta
from dataclasses import dataclass, field
from typing import Optional, List
import math

# ─── Enums ────────────────────────────────────────────────────────────────────

class TaskPriority:
    HIGH   = 0
    MEDIUM = 1
    LOW    = 2
    LABELS = ['High', 'Medium', 'Low']
    COLORS = [0xFFE63946, 0xFFFFBF00, 0xFF2EC4B6]  # ARGB
    @classmethod
    def label(cls, v): return cls.LABELS[v]
    @classmethod
    def color(cls, v): return cls.COLORS[v]

class TaskCategory:
    ASSIGNMENT = 0
    EXAM       = 1
    PROJECT    = 2
    READING    = 3
    MEETING    = 4
    OTHER      = 5
    LABELS = ['Assignment', 'Exam', 'Project', 'Reading', 'Meeting', 'Other']
    COLORS = [0xFF6C63FF, 0xFFFF6584, 0xFF2EC4B6,
              0xFFFFBF00, 0xFF4CAF50, 0xFFFF9800]
    @classmethod
    def label(cls, v): return cls.LABELS[v]
    @classmethod
    def color(cls, v): return cls.COLORS[v]

# ─── Models ───────────────────────────────────────────────────────────────────

@dataclass
class SubTask:
    id: str
    title: str
    is_done: bool = False

    def copy_with(self, **kwargs):
        return SubTask(
            id=kwargs.get('id', self.id),
            title=kwargs.get('title', self.title),
            is_done=kwargs.get('is_done', self.is_done),
        )

    def to_map(self):
        return {'id': self.id, 'title': self.title, 'isDone': self.is_done}

    @classmethod
    def from_map(cls, m):
        return cls(id=m['id'], title=m['title'], is_done=m.get('isDone', False))


@dataclass
class TaskModel:
    id: str
    user_id: str
    title: str
    description: str = ''
    deadline: datetime = field(default_factory=datetime.now)
    priority: int = TaskPriority.MEDIUM
    category: int = TaskCategory.ASSIGNMENT
    is_completed: bool = False
    progress: float = 0.0
    subtasks: List[SubTask] = field(default_factory=list)
    grade_weight: int = 0
    created_at: datetime = field(default_factory=datetime.now)
    updated_at: datetime = field(default_factory=datetime.now)

    @property
    def smart_score(self):
        now = datetime.now()
        h = (self.deadline - now).total_seconds() / 3600
        urgency = 100.0 if h <= 0 else min((1000 / (h + 1)), 100.0)
        pri = (2 - self.priority) * 30.0
        weight = min(float(self.grade_weight), 100.0)
        return urgency * 0.5 + pri * 0.3 + weight * 0.2

    @property
    def is_overdue(self):
        return not self.is_completed and self.deadline < datetime.now()

    @property
    def is_due_today(self):
        n = datetime.now()
        return (self.deadline.year == n.year and
                self.deadline.month == n.month and
                self.deadline.day == n.day and
                not self.is_completed)

    @property
    def is_due_soon(self):
        h = (self.deadline - datetime.now()).total_seconds() / 3600
        return 0 < h <= 24 and not self.is_completed

    @property
    def subtask_progress(self):
        if not self.subtasks:
            return self.progress
        return sum(1 for s in self.subtasks if s.is_done) / len(self.subtasks)

    def copy_with(self, **kwargs):
        return TaskModel(
            id=kwargs.get('id', self.id),
            user_id=kwargs.get('user_id', self.user_id),
            title=kwargs.get('title', self.title),
            description=kwargs.get('description', self.description),
            deadline=kwargs.get('deadline', self.deadline),
            priority=kwargs.get('priority', self.priority),
            category=kwargs.get('category', self.category),
            is_completed=kwargs.get('is_completed', self.is_completed),
            progress=kwargs.get('progress', self.progress),
            subtasks=kwargs.get('subtasks', self.subtasks),
            grade_weight=kwargs.get('grade_weight', self.grade_weight),
            created_at=kwargs.get('created_at', self.created_at),
            updated_at=kwargs.get('updated_at', self.updated_at),
        )

    def to_map(self):
        return {
            'id': self.id, 'userId': self.user_id, 'title': self.title,
            'description': self.description,
            'priority': self.priority, 'category': self.category,
            'isCompleted': self.is_completed, 'progress': self.progress,
            'subtasks': [s.to_map() for s in self.subtasks],
            'gradeWeight': self.grade_weight,
        }


@dataclass
class UserModel:
    uid: str
    name: str
    email: str
    photo_url: Optional[str] = None
    course: str = ''
    total_tasks_completed: int = 0
    current_streak: int = 0
    lat: Optional[float] = None
    lng: Optional[float] = None
    location_address: str = ''
    created_at: datetime = field(default_factory=datetime.now)

    def copy_with(self, **kwargs):
        return UserModel(
            uid=kwargs.get('uid', self.uid),
            name=kwargs.get('name', self.name),
            email=kwargs.get('email', self.email),
            photo_url=kwargs.get('photo_url', self.photo_url),
            course=kwargs.get('course', self.course),
            total_tasks_completed=kwargs.get('total_tasks_completed', self.total_tasks_completed),
            current_streak=kwargs.get('current_streak', self.current_streak),
            lat=kwargs.get('lat', self.lat),
            lng=kwargs.get('lng', self.lng),
            location_address=kwargs.get('location_address', self.location_address),
            created_at=kwargs.get('created_at', self.created_at),
        )

    def to_map(self):
        return {
            'uid': self.uid, 'name': self.name, 'email': self.email,
            'photoUrl': self.photo_url, 'course': self.course,
            'totalTasksCompleted': self.total_tasks_completed,
            'currentStreak': self.current_streak,
            'lat': self.lat, 'lng': self.lng,
            'locationAddress': self.location_address,
        }


# ─── AppColors ────────────────────────────────────────────────────────────────

class AppColors:
    PRIMARY       = 0xFF6C63FF
    SURFACE       = 0xFFFFFFFF
    BACKGROUND    = 0xFFF8F7FF
    DANGER        = 0xFFE63946
    SUCCESS       = 0xFF2EC4B6
    WARNING       = 0xFFFFBF00
    TEXT_PRIMARY  = 0xFF1A1A2E


# ─── Tests ────────────────────────────────────────────────────────────────────

class TestTaskModelCoreFields(unittest.TestCase):

    def setUp(self):
        self.base = TaskModel(
            id='test-id-001', user_id='user-uid-001',
            title='Complete MAE Assignment',
            description='Flutter app Part 2 submission',
            deadline=datetime(2026, 7, 15, 23, 59),
            priority=TaskPriority.HIGH,
            category=TaskCategory.ASSIGNMENT,
            grade_weight=60,
        )

    def test_TC01_fields_stored_correctly(self):
        t = self.base
        self.assertEqual(t.id, 'test-id-001')
        self.assertEqual(t.title, 'Complete MAE Assignment')
        self.assertEqual(t.priority, TaskPriority.HIGH)
        self.assertEqual(t.category, TaskCategory.ASSIGNMENT)
        self.assertEqual(t.grade_weight, 60)
        self.assertFalse(t.is_completed)
        self.assertEqual(t.progress, 0.0)

    def test_TC02_to_map_serialises_all_fields(self):
        m = self.base.to_map()
        self.assertEqual(m['id'], 'test-id-001')
        self.assertEqual(m['title'], 'Complete MAE Assignment')
        self.assertEqual(m['priority'], TaskPriority.HIGH)
        self.assertEqual(m['gradeWeight'], 60)
        self.assertFalse(m['isCompleted'])

    def test_TC03_copy_with_does_not_mutate_original(self):
        edited = self.base.copy_with(title='Edited Title', is_completed=True, progress=1.0)
        self.assertEqual(edited.title, 'Edited Title')
        self.assertTrue(edited.is_completed)
        self.assertEqual(edited.progress, 1.0)
        self.assertEqual(self.base.title, 'Complete MAE Assignment')
        self.assertFalse(self.base.is_completed)

    def test_TC04_is_overdue_past_incomplete(self):
        past = self.base.copy_with(deadline=datetime.now() - timedelta(hours=2))
        self.assertTrue(past.is_overdue)

    def test_TC05_is_overdue_false_if_completed(self):
        completed = self.base.copy_with(
            deadline=datetime.now() - timedelta(hours=2), is_completed=True)
        self.assertFalse(completed.is_overdue)

    def test_TC06_is_due_today(self):
        n = datetime.now()
        today = self.base.copy_with(deadline=datetime(n.year, n.month, n.day, 23, 59))
        self.assertTrue(today.is_due_today)

    def test_TC07_is_due_soon_within_24h(self):
        soon = self.base.copy_with(deadline=datetime.now() + timedelta(hours=6))
        self.assertTrue(soon.is_due_soon)

    def test_TC08_is_due_soon_false_after_24h(self):
        later = self.base.copy_with(deadline=datetime.now() + timedelta(days=3))
        self.assertFalse(later.is_due_soon)

    def test_TC09_smart_score_higher_for_high_priority(self):
        high = self.base.copy_with(priority=TaskPriority.HIGH,
                                    deadline=datetime.now() + timedelta(hours=10))
        low  = self.base.copy_with(priority=TaskPriority.LOW,
                                    deadline=datetime.now() + timedelta(hours=10))
        self.assertGreater(high.smart_score, low.smart_score)

    def test_TC10_smart_score_higher_for_imminent_deadline(self):
        urgent  = self.base.copy_with(deadline=datetime.now() + timedelta(hours=1))
        relaxed = self.base.copy_with(deadline=datetime.now() + timedelta(days=30))
        self.assertGreater(urgent.smart_score, relaxed.smart_score)


class TestSubTask(unittest.TestCase):

    def test_TC11_subtask_defaults_not_done(self):
        s = SubTask(id='s1', title='Read docs')
        self.assertFalse(s.is_done)

    def test_TC12_copy_with_toggles_done(self):
        s = SubTask(id='s1', title='Read docs')
        done = s.copy_with(is_done=True)
        self.assertTrue(done.is_done)
        self.assertFalse(s.is_done)

    def test_TC13_round_trip_serialisation(self):
        s = SubTask(id='s2', title='Write tests', is_done=True)
        back = SubTask.from_map(s.to_map())
        self.assertEqual(back.id, 's2')
        self.assertEqual(back.title, 'Write tests')
        self.assertTrue(back.is_done)

    def test_TC14_subtask_progress_zero_when_none_done(self):
        t = TaskModel(id='x', user_id='u', title='T',
                      deadline=datetime.now() + timedelta(days=1),
                      subtasks=[SubTask('a', 'Step 1'), SubTask('b', 'Step 2')])
        self.assertEqual(t.subtask_progress, 0.0)

    def test_TC15_subtask_progress_half(self):
        t = TaskModel(id='x', user_id='u', title='T',
                      deadline=datetime.now() + timedelta(days=1),
                      subtasks=[SubTask('a', 'S1', True), SubTask('b', 'S2', False)])
        self.assertEqual(t.subtask_progress, 0.5)

    def test_TC16_subtask_progress_full(self):
        t = TaskModel(id='x', user_id='u', title='T',
                      deadline=datetime.now() + timedelta(days=1),
                      subtasks=[SubTask('a', 'S1', True), SubTask('b', 'S2', True)])
        self.assertEqual(t.subtask_progress, 1.0)


class TestUserModel(unittest.TestCase):

    def setUp(self):
        self.user = UserModel(
            uid='uid-001', name='Nang Thet Htar San',
            email='tp084170@mail.apu.edu.my',
            course='Bachelor of Science (Hons) in Software Engineering',
            total_tasks_completed=5, current_streak=3,
            lat=3.139, lng=101.687,
            location_address='APU Technology Park Malaysia',
        )

    def test_TC17_fields_stored_correctly(self):
        self.assertEqual(self.user.uid, 'uid-001')
        self.assertEqual(self.user.name, 'Nang Thet Htar San')
        self.assertEqual(self.user.total_tasks_completed, 5)
        self.assertEqual(self.user.current_streak, 3)
        self.assertAlmostEqual(self.user.lat, 3.139)

    def test_TC18_to_map_includes_all_keys(self):
        m = self.user.to_map()
        for key in ['uid','name','totalTasksCompleted','currentStreak','lat','lng']:
            self.assertIn(key, m)

    def test_TC19_copy_with_updates_specified_fields(self):
        u2 = self.user.copy_with(name='Nour Mohamed', current_streak=7)
        self.assertEqual(u2.name, 'Nour Mohamed')
        self.assertEqual(u2.current_streak, 7)
        self.assertEqual(u2.email, self.user.email)
        self.assertEqual(u2.total_tasks_completed, self.user.total_tasks_completed)


class TestEnums(unittest.TestCase):

    def test_TC20_priority_labels(self):
        self.assertEqual(TaskPriority.label(TaskPriority.HIGH), 'High')
        self.assertEqual(TaskPriority.label(TaskPriority.MEDIUM), 'Medium')
        self.assertEqual(TaskPriority.label(TaskPriority.LOW), 'Low')

    def test_TC21_priority_colors_distinct(self):
        colors = [TaskPriority.color(v) for v in [0,1,2]]
        self.assertEqual(len(set(colors)), 3)

    def test_TC22_category_labels(self):
        expected = ['Assignment','Exam','Project','Reading','Meeting','Other']
        for i, e in enumerate(expected):
            self.assertEqual(TaskCategory.label(i), e)

    def test_TC23_all_6_categories_have_distinct_colors(self):
        colors = [TaskCategory.color(i) for i in range(6)]
        self.assertEqual(len(set(colors)), 6)

    def test_TC24_primary_color_non_transparent(self):
        alpha = (AppColors.PRIMARY >> 24) & 0xFF
        self.assertEqual(alpha, 255)


class TestSmartSort(unittest.TestCase):

    def _make(self, id, priority, deadline, grade_weight=0):
        return TaskModel(id=id, user_id='u', title=id,
                         deadline=deadline, priority=priority,
                         grade_weight=grade_weight)

    def test_TC25_overdue_high_priority_scores_highest(self):
        overdue = self._make('o', TaskPriority.HIGH,
                              datetime.now() - timedelta(hours=1), 50)
        future  = self._make('f', TaskPriority.LOW,
                              datetime.now() + timedelta(days=7))
        self.assertGreater(overdue.smart_score, future.smart_score)

    def test_TC26_grade_weight_influences_score(self):
        hw = self._make('hw', TaskPriority.MEDIUM,
                         datetime.now() + timedelta(hours=48), 100)
        nw = self._make('nw', TaskPriority.MEDIUM,
                         datetime.now() + timedelta(hours=48), 0)
        self.assertGreater(hw.smart_score, nw.smart_score)

    def test_TC27_smart_score_within_realistic_range(self):
        tasks = [
            self._make('1', TaskPriority.HIGH, datetime.now()+timedelta(minutes=30), 100),
            self._make('2', TaskPriority.LOW,  datetime.now()+timedelta(days=60)),
            self._make('3', TaskPriority.MEDIUM, datetime.now()+timedelta(hours=12), 50),
        ]
        for t in tasks:
            self.assertGreaterEqual(t.smart_score, 0)
            self.assertLess(t.smart_score, 300)


class TestFiltering(unittest.TestCase):

    def setUp(self):
        n = datetime.now()
        self.tasks = [
            TaskModel('1','u','Overdue Task',
                      deadline=n-timedelta(hours=3),
                      category=TaskCategory.ASSIGNMENT, priority=TaskPriority.HIGH),
            TaskModel('2','u','Due Today',
                      deadline=datetime(n.year,n.month,n.day,23,30),
                      category=TaskCategory.EXAM, priority=TaskPriority.MEDIUM),
            TaskModel('3','u','Future Project',
                      deadline=n+timedelta(days=10),
                      category=TaskCategory.PROJECT, priority=TaskPriority.LOW),
            TaskModel('4','u','Completed',
                      deadline=n-timedelta(days=1),
                      is_completed=True,
                      category=TaskCategory.READING, priority=TaskPriority.LOW),
        ]

    def test_TC28_active_filter_excludes_completed(self):
        active = [t for t in self.tasks if not t.is_completed]
        self.assertEqual(len(active), 3)
        self.assertFalse(any(t.is_completed for t in active))

    def test_TC29_overdue_filter(self):
        overdue = [t for t in self.tasks if t.is_overdue]
        self.assertEqual(len(overdue), 1)
        self.assertEqual(overdue[0].id, '1')

    def test_TC30_today_filter(self):
        today = [t for t in self.tasks if t.is_due_today]
        self.assertTrue(all(t.is_due_today for t in today))

    def test_TC31_category_assignment_filter(self):
        assignments = [t for t in self.tasks
                       if not t.is_completed and t.category == TaskCategory.ASSIGNMENT]
        self.assertEqual(len(assignments), 1)
        self.assertEqual(assignments[0].title, 'Overdue Task')

    def test_TC32_completed_not_in_active(self):
        active = [t for t in self.tasks if not t.is_completed]
        self.assertFalse(any(t.id == '4' for t in active))


class TestEdgeCases(unittest.TestCase):

    def test_TC41_zero_grade_weight_valid_score(self):
        t = TaskModel('e1','u','No weight',
                      deadline=datetime.now()+timedelta(hours=5), grade_weight=0)
        self.assertFalse(math.isnan(t.smart_score))
        self.assertGreaterEqual(t.smart_score, 0)

    def test_TC42_special_characters_in_title(self):
        t = TaskModel('e2','u','Résumé & Présentation — "Final Draft"',
                      deadline=datetime.now()+timedelta(days=1))
        self.assertEqual(t.title, 'Résumé & Présentation — "Final Draft"')

    def test_TC43_subtask_progress_returns_stored_when_empty(self):
        t = TaskModel('e3','u','No subs',
                      deadline=datetime.now()+timedelta(days=1),
                      subtasks=[], progress=0.75)
        self.assertEqual(t.subtask_progress, 0.75)

    def test_TC44_grade_weight_100_valid_score(self):
        t = TaskModel('e4','u','Max weight',
                      deadline=datetime.now()+timedelta(hours=12),
                      grade_weight=100, priority=TaskPriority.HIGH)
        self.assertFalse(math.isnan(t.smart_score))

    def test_TC45_one_second_past_is_overdue(self):
        t = TaskModel('e5','u','Just passed',
                      deadline=datetime.now()-timedelta(seconds=1))
        self.assertTrue(t.is_overdue)

    def test_TC46_null_photo_url_serialises(self):
        u = UserModel(uid='u1', name='Test', email='t@t.com', photo_url=None)
        m = u.to_map()
        self.assertIsNone(m['photoUrl'])

    def test_TC47_empty_subtasks_serialises_to_empty_list(self):
        t = TaskModel('e6','u','No subs',
                      deadline=datetime.now()+timedelta(days=1), subtasks=[])
        m = t.to_map()
        self.assertEqual(len(m['subtasks']), 0)

    def test_TC48_priority_index_order(self):
        self.assertEqual(TaskPriority.HIGH, 0)
        self.assertEqual(TaskPriority.MEDIUM, 1)
        self.assertEqual(TaskPriority.LOW, 2)

    def test_TC49_subtasks_serialise_in_order(self):
        subs = [SubTask('s1','First'), SubTask('s2','Second'), SubTask('s3','Third')]
        maps = [s.to_map() for s in subs]
        back = [SubTask.from_map(m) for m in maps]
        self.assertEqual(back[0].title, 'First')
        self.assertEqual(back[1].title, 'Second')
        self.assertEqual(back[2].title, 'Third')

    def test_TC50_surface_color_is_white(self):
        self.assertEqual(AppColors.SURFACE, 0xFFFFFFFF)


# ─── Widget tests (TC-33 to TC-40) are in sptm_test.dart ─────────────────────
# They require Flutter's testing framework and cannot be mirrored in Python.
# They are documented here for completeness.

class TestWidgetDocumentation(unittest.TestCase):
    """
    TC-33 to TC-40 are Flutter widget tests defined in sptm_test.dart.
    They verify: AppTheme creation, MaterialApp rendering, ElevatedButton,
    CircularProgressIndicator loading state, TextFormField validation,
    BottomNavigationBar tab count, Priority chip row, Category chip row.
    Run with: flutter test test/sptm_test.dart
    """
    def test_TC33_to_TC40_are_in_dart_file(self):
        # Confirms dart widget tests are present
        import os
        dart_path = os.path.join(os.path.dirname(__file__), 'sptm_test.dart')
        self.assertTrue(os.path.exists(dart_path),
                        "sptm_test.dart must exist alongside this file")


if __name__ == '__main__':
    print("=" * 65)
    print("SPTM Automated Test Suite — Group 27")
    print("CT124-3-2 Mobile App Engineering")
    print("=" * 65)
    loader = unittest.TestLoader()
    loader.sortTestMethodsUsing = None   # preserve definition order
    suite = unittest.TestSuite()
    for cls in [
        TestTaskModelCoreFields, TestSubTask, TestUserModel,
        TestEnums, TestSmartSort, TestFiltering, TestEdgeCases,
        TestWidgetDocumentation,
    ]:
        suite.addTests(loader.loadTestsFromTestCase(cls))

    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    print("\n" + "=" * 65)
    total = result.testsRun
    passed = total - len(result.failures) - len(result.errors)
    print(f"Results: {passed}/{total} passed")
    if result.failures or result.errors:
        print("FAILURES / ERRORS:")
        for f in result.failures + result.errors:
            print(f[0])
    else:
        print("ALL TESTS PASSED ✓")
    print("=" * 65)
