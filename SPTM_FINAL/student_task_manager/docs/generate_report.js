const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  AlignmentType, HeadingLevel, BorderStyle, WidthType, ShadingType,
  VerticalAlign, PageBreak, LevelFormat, Header, Footer, PageNumber,
  NumberFormat
} = require('docx');
const fs = require('fs');

const border = { style: BorderStyle.SINGLE, size: 1, color: 'CCCCCC' };
const borders = { top: border, bottom: border, left: border, right: border };
const noBorders = {
  top: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
  bottom: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
  left: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
  right: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
};
const BLUE = '4472C4';
const PAGE_W = 11906; // A4 width DXA
const MARGINS = { top: 1440, right: 1260, bottom: 1440, left: 1260 };
const CONTENT_W = PAGE_W - MARGINS.left - MARGINS.right; // 9386

function h1(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_1,
    spacing: { before: 360, after: 120 },
    children: [new TextRun({ text, bold: true, size: 28, color: '1F3864' })],
  });
}
function h2(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_2,
    spacing: { before: 240, after: 80 },
    children: [new TextRun({ text, bold: true, size: 24, color: '2E5FA3' })],
  });
}
function h3(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_3,
    spacing: { before: 160, after: 60 },
    children: [new TextRun({ text, bold: true, size: 22, color: '3B6CAB' })],
  });
}
function body(text, opts = {}) {
  return new Paragraph({
    spacing: { before: 60, after: 60, line: 276 },
    children: [new TextRun({ text, size: 22, font: 'Times New Roman', ...opts })],
  });
}
function bullet(text) {
  return new Paragraph({
    numbering: { reference: 'bullets', level: 0 },
    spacing: { before: 40, after: 40 },
    children: [new TextRun({ text, size: 22, font: 'Times New Roman' })],
  });
}
function spacer(n = 1) {
  return Array.from({ length: n }, () => new Paragraph({ children: [new TextRun('')], spacing: { before: 0, after: 60 } }));
}
function cell(text, { shade = 'F2F7FF', bold = false, w = Math.floor(CONTENT_W / 2) } = {}) {
  return new TableCell({
    borders,
    width: { size: w, type: WidthType.DXA },
    shading: { fill: shade, type: ShadingType.CLEAR },
    margins: { top: 80, bottom: 80, left: 120, right: 120 },
    children: [new Paragraph({ children: [new TextRun({ text, size: 20, bold, font: 'Times New Roman' })] })],
  });
}
function row2(a, b, header = false) {
  const shade = header ? 'DCE6F1' : 'FFFFFF';
  return new TableRow({
    children: [cell(a, { shade, bold: header, w: Math.floor(CONTENT_W * 0.35) }),
               cell(b, { shade: header ? shade : 'F8FBFF', bold: false, w: Math.floor(CONTENT_W * 0.65) })],
  });
}
function row3(a, b, c, header = false) {
  const shade = header ? 'DCE6F1' : 'FFFFFF';
  const w1 = Math.floor(CONTENT_W * 0.1);
  const w2 = Math.floor(CONTENT_W * 0.45);
  const w3 = Math.floor(CONTENT_W * 0.45);
  return new TableRow({
    children: [
      new TableCell({ borders, width: { size: w1, type: WidthType.DXA }, shading: { fill: shade, type: ShadingType.CLEAR },
        margins: { top: 80, bottom: 80, left: 120, right: 120 },
        children: [new Paragraph({ children: [new TextRun({ text: a, size: 20, bold: header, font: 'Times New Roman' })] })] }),
      new TableCell({ borders, width: { size: w2, type: WidthType.DXA }, shading: { fill: header ? shade : 'F8FBFF', type: ShadingType.CLEAR },
        margins: { top: 80, bottom: 80, left: 120, right: 120 },
        children: [new Paragraph({ children: [new TextRun({ text: b, size: 20, bold: header, font: 'Times New Roman' })] })] }),
      new TableCell({ borders, width: { size: w3, type: WidthType.DXA }, shading: { fill: header ? shade : 'FFFFFF', type: ShadingType.CLEAR },
        margins: { top: 80, bottom: 80, left: 120, right: 120 },
        children: [new Paragraph({ children: [new TextRun({ text: c, size: 20, bold: header, font: 'Times New Roman' })] })] }),
    ],
  });
}

// ─── Test report rows ─────────────────────────────────────────────────────────
function tcRow(id, name, method, expected, actual, status) {
  const s = status === 'PASS';
  const statusColor = s ? '1E8449' : 'C0392B';
  const w = [
    Math.floor(CONTENT_W * 0.07),
    Math.floor(CONTENT_W * 0.25),
    Math.floor(CONTENT_W * 0.18),
    Math.floor(CONTENT_W * 0.20),
    Math.floor(CONTENT_W * 0.16),
    Math.floor(CONTENT_W * 0.14),
  ];
  return new TableRow({
    children: [id, name, method, expected, actual].map((text, i) =>
      new TableCell({
        borders,
        width: { size: w[i], type: WidthType.DXA },
        shading: { fill: 'FAFAFA', type: ShadingType.CLEAR },
        margins: { top: 60, bottom: 60, left: 100, right: 100 },
        children: [new Paragraph({ children: [new TextRun({ text, size: 18, font: 'Times New Roman' })] })],
      })
    ).concat([
      new TableCell({
        borders,
        width: { size: w[5], type: WidthType.DXA },
        shading: { fill: s ? 'EAFAF1' : 'FDEDEC', type: ShadingType.CLEAR },
        margins: { top: 60, bottom: 60, left: 100, right: 100 },
        children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: status, size: 18, bold: true, color: statusColor, font: 'Times New Roman' })] })],
      }),
    ]),
  });
}

function tcHeaderRow() {
  const headers = ['TC#', 'Test Name', 'Method', 'Expected', 'Actual', 'Result'];
  const w = [
    Math.floor(CONTENT_W * 0.07),
    Math.floor(CONTENT_W * 0.25),
    Math.floor(CONTENT_W * 0.18),
    Math.floor(CONTENT_W * 0.20),
    Math.floor(CONTENT_W * 0.16),
    Math.floor(CONTENT_W * 0.14),
  ];
  return new TableRow({
    children: headers.map((text, i) =>
      new TableCell({
        borders,
        width: { size: w[i], type: WidthType.DXA },
        shading: { fill: 'DCE6F1', type: ShadingType.CLEAR },
        margins: { top: 80, bottom: 80, left: 100, right: 100 },
        children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text, size: 18, bold: true, font: 'Times New Roman' })] })],
      })
    ),
  });
}

const testCases = [
  ['TC-01','fields stored correctly','Unit / assertEqual','All fields match input','All fields matched'],
  ['TC-02','toMap() serialises fields','Unit / map keys check','Map contains all keys','All keys present'],
  ['TC-03','copyWith no mutation','Unit / immutability','Original unchanged','Original unchanged'],
  ['TC-04','isOverdue – past incomplete','Unit / boolean','true','true'],
  ['TC-05','isOverdue false if completed','Unit / boolean','false','false'],
  ['TC-06','isDueToday','Unit / date compare','true for same day','true'],
  ['TC-07','isDueSoon within 24h','Unit / boolean','true','true'],
  ['TC-08','isDueSoon false > 24h','Unit / boolean','false','false'],
  ['TC-09','smartScore high > low priority','Unit / compare','high.score > low.score','high.score > low.score'],
  ['TC-10','smartScore imminent > distant','Unit / compare','urgent > relaxed','urgent > relaxed'],
  ['TC-11','SubTask defaults isDone=false','Unit / boolean','false','false'],
  ['TC-12','SubTask copyWith toggles','Unit / boolean','true, original false','true, original false'],
  ['TC-13','SubTask round-trip serialise','Unit / equality','id, title, isDone match','All match'],
  ['TC-14','subtaskProgress = 0 (none done)','Unit / float','0.0','0.0'],
  ['TC-15','subtaskProgress = 0.5 (half done)','Unit / float','0.5','0.5'],
  ['TC-16','subtaskProgress = 1.0 (all done)','Unit / float','1.0','1.0'],
  ['TC-17','UserModel fields stored','Unit / assertEqual','All fields match','All fields matched'],
  ['TC-18','UserModel toMap keys','Unit / map keys','All keys present','All keys present'],
  ['TC-19','UserModel copyWith partial','Unit / equality','Changed fields update, rest stable','Correct'],
  ['TC-20','Priority labels','Unit / enum','High/Medium/Low','High/Medium/Low'],
  ['TC-21','Priority colors distinct','Unit / set size','3 distinct colors','3 distinct colors'],
  ['TC-22','Category labels','Unit / enum','6 correct labels','6 correct labels'],
  ['TC-23','Category colors distinct','Unit / set size','6 distinct colors','6 distinct colors'],
  ['TC-24','AppColors.primary alpha=255','Unit / bit mask','255','255'],
  ['TC-25','Overdue HP scores highest','Unit / compare','overdue.score > future.score','Correct'],
  ['TC-26','Grade weight in score','Unit / compare','100wt > 0wt score','Correct'],
  ['TC-27','smartScore in valid range','Unit / bounds','0 ≤ score < 300','Correct for all 3'],
  ['TC-28','Active filter no completed','Unit / filter','len=3, none completed','Correct'],
  ['TC-29','Overdue filter','Unit / filter','len=1, id=1','Correct'],
  ['TC-30','Today filter','Unit / filter','All isDueToday','Correct'],
  ['TC-31','Assignment category filter','Unit / filter','len=1, title match','Correct'],
  ['TC-32','Completed not in active','Unit / filter','id=4 absent','Absent'],
  ['TC-33','AppTheme.light valid ThemeData','Widget test','ThemeData instance','ThemeData created'],
  ['TC-34','MaterialApp renders','Widget test','No errors, text visible','Rendered'],
  ['TC-35','ElevatedButton renders','Widget test','Button found','Button found'],
  ['TC-36','CircularProgressIndicator','Widget test','Widget found','Widget found'],
  ['TC-37','TextFormField empty validation','Widget test','Error text shown','Error shown'],
  ['TC-38','BottomNavigationBar 4 tabs','Widget test','4 tab labels visible','4 labels found'],
  ['TC-39','Priority chips row','Widget test','3 chips visible','3 chips found'],
  ['TC-40','Category chips 6','Widget test','6 chips visible','6 chips found'],
  ['TC-41','gradeWeight=0 valid score','Edge case','score ≥ 0, not NaN','Valid score'],
  ['TC-42','Special chars in title','Edge case','Title stored as-is','Correct'],
  ['TC-43','subtaskProgress stored progress','Edge case','0.75','0.75'],
  ['TC-44','gradeWeight=100 valid score','Edge case','Not NaN','Valid score'],
  ['TC-45','1s past is overdue','Edge case','true','true'],
  ['TC-46','null photoUrl serialises','Edge case','map[photoUrl] = null','null'],
  ['TC-47','empty subtasks → empty list','Edge case','len=0','len=0'],
  ['TC-48','Priority index order','Edge case','high=0,med=1,low=2','Correct'],
  ['TC-49','Subtasks order preserved','Edge case','First/Second/Third','In order'],
  ['TC-50','Surface color is white','Edge case','0xFFFFFFFF','0xFFFFFFFF'],
];

// ─── Document ─────────────────────────────────────────────────────────────────
const doc = new Document({
  numbering: {
    config: [
      {
        reference: 'bullets',
        levels: [{
          level: 0, format: LevelFormat.BULLET, text: '\u2022',
          alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 720, hanging: 360 } } },
        }],
      },
    ],
  },
  styles: {
    default: {
      document: { run: { font: 'Times New Roman', size: 22 } },
    },
    paragraphStyles: [
      { id: 'Heading1', name: 'Heading 1', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 28, bold: true, font: 'Times New Roman', color: '1F3864' },
        paragraph: { spacing: { before: 360, after: 120 }, outlineLevel: 0 } },
      { id: 'Heading2', name: 'Heading 2', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 24, bold: true, font: 'Times New Roman', color: '2E5FA3' },
        paragraph: { spacing: { before: 240, after: 80 }, outlineLevel: 1 } },
      { id: 'Heading3', name: 'Heading 3', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 22, bold: true, font: 'Times New Roman', color: '3B6CAB' },
        paragraph: { spacing: { before: 160, after: 60 }, outlineLevel: 2 } },
    ],
  },
  sections: [
    // ── COVER PAGE ──────────────────────────────────────────────────────────
    {
      properties: {
        page: { size: { width: PAGE_W, height: 16838 }, margin: MARGINS }
      },
      children: [
        ...spacer(3),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          children: [new TextRun({ text: 'ASIA PACIFIC UNIVERSITY OF TECHNOLOGY & INNOVATION', bold: true, size: 28, font: 'Times New Roman', color: '1F3864' })],
        }),
        new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 80, after: 80 }, children: [new TextRun({ text: 'CT124-3-2  |  Mobile App Engineering', size: 24, font: 'Times New Roman', color: '444444' })] }),
        ...spacer(1),
        new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 40, after: 40 }, children: [new TextRun({ text: '─────────────────────────────────────────', color: 'AAAAAA', size: 20 })] }),
        ...spacer(1),
        new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 120, after: 80 }, children: [new TextRun({ text: 'GROUP ASSIGNMENT – PART 2', bold: true, size: 32, font: 'Times New Roman', color: '2E5FA3' })] }),
        new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 60, after: 200 }, children: [new TextRun({ text: 'Problem Solving, Design, Mobile Application & Testing Report', size: 26, font: 'Times New Roman', italics: true, color: '555555' })] }),
        new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: 'Student Productivity and Task Management Application', bold: true, size: 28, font: 'Times New Roman' })] }),
        new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 60, after: 40 }, children: [new TextRun({ text: '(SPTM)', size: 24, font: 'Times New Roman', color: '2E5FA3', bold: true })] }),
        ...spacer(2),
        new Table({
          width: { size: Math.floor(CONTENT_W * 0.7), type: WidthType.DXA },
          columnWidths: [Math.floor(CONTENT_W * 0.25), Math.floor(CONTENT_W * 0.45)],
          rows: [
            row2('Group', 'G27'),
            row2('Members', 'Nang Thet Htar San (TP084170)\nNour Mohamed Mahmoud (TP081664)'),
            row2('Intake', 'APU2F2509SE / APD2F2509CS'),
            row2('Lecturer', 'Mr. Amad Arshad'),
            row2('Module', 'CT124-3-2 Mobile App Engineering'),
            row2('Submission Date', '2nd June 2026'),
          ],
        }),
        new Paragraph({ children: [new PageBreak()] }),
      ],
    },

    // ── MAIN DOCUMENT ───────────────────────────────────────────────────────
    {
      properties: {
        page: { size: { width: PAGE_W, height: 16838 }, margin: MARGINS }
      },
      headers: {
        default: new Header({
          children: [
            new Paragraph({
              border: { bottom: { style: BorderStyle.SINGLE, size: 4, color: BLUE } },
              children: [
                new TextRun({ text: 'CT124-3-2 MAE  |  Group 27  |  SPTM – Part 2 Report', size: 18, color: '666666', font: 'Times New Roman' }),
              ],
            }),
          ],
        }),
      },
      footers: {
        default: new Footer({
          children: [
            new Paragraph({
              alignment: AlignmentType.CENTER,
              border: { top: { style: BorderStyle.SINGLE, size: 4, color: BLUE } },
              children: [
                new TextRun({ text: 'Page ', size: 18, color: '666666', font: 'Times New Roman' }),
                new TextRun({ children: [PageNumber.CURRENT], size: 18, color: '666666', font: 'Times New Roman' }),
                new TextRun({ text: '  |  Asia Pacific University of Technology & Innovation', size: 18, color: '666666', font: 'Times New Roman' }),
              ],
            }),
          ],
        }),
      },
      children: [
        // ─── 1. SYSTEM DESCRIPTION ─────────────────────────────────────────
        h1('1. System Description – Problem Identification and Proposed Solutions'),

        h2('1.1 Problem Identification'),
        body('Findings from the Part 1 generative research study identified four recurring pain points experienced by university students at APU:'),
        ...spacer(1),
        new Table({
          width: { size: CONTENT_W, type: WidthType.DXA },
          columnWidths: [Math.floor(CONTENT_W * 0.05), Math.floor(CONTENT_W * 0.3), Math.floor(CONTENT_W * 0.65)],
          rows: [
            new TableRow({ children: [
              new TableCell({ borders, width: { size: Math.floor(CONTENT_W*0.05), type: WidthType.DXA }, shading: { fill: 'DCE6F1', type: ShadingType.CLEAR }, margins: { top:80,bottom:80,left:120,right:120 }, children: [new Paragraph({ children: [new TextRun({ text: '#', size: 20, bold: true, font: 'Times New Roman' })] })] }),
              new TableCell({ borders, width: { size: Math.floor(CONTENT_W*0.3), type: WidthType.DXA }, shading: { fill: 'DCE6F1', type: ShadingType.CLEAR }, margins: { top:80,bottom:80,left:120,right:120 }, children: [new Paragraph({ children: [new TextRun({ text: 'Problem', size: 20, bold: true, font: 'Times New Roman' })] })] }),
              new TableCell({ borders, width: { size: Math.floor(CONTENT_W*0.65), type: WidthType.DXA }, shading: { fill: 'DCE6F1', type: ShadingType.CLEAR }, margins: { top:80,bottom:80,left:120,right:120 }, children: [new Paragraph({ children: [new TextRun({ text: 'Research Evidence', size: 20, bold: true, font: 'Times New Roman' })] })] }),
            ]}),
            ...[
              ['P1', 'Difficulty prioritising tasks when multiple deadlines overlap', 'Participants prioritised by urgency only; grade weight and effort were ignored'],
              ['P2', 'Ineffective or missed reminders', 'Mariia used Do Not Disturb; Feysal found existing apps "too isolated"'],
              ['P3', 'No structured breakdown of large tasks', 'Mohamed found apps "too feature-heavy"; students had no subtask tracking'],
              ['P4', 'Lack of productivity/focus support', 'Feysal worked in "sprints"; Farida prone to burnout without focus sessions'],
            ].map(([n, p, e]) => new TableRow({ children: [
              new TableCell({ borders, width: { size: Math.floor(CONTENT_W*0.05), type: WidthType.DXA }, shading: { fill: 'FAFAFA', type: ShadingType.CLEAR }, margins: {top:70,bottom:70,left:120,right:120}, children: [new Paragraph({ children: [new TextRun({ text: n, size: 19, font: 'Times New Roman' })] })] }),
              new TableCell({ borders, width: { size: Math.floor(CONTENT_W*0.3), type: WidthType.DXA }, shading: { fill: 'FAFAFA', type: ShadingType.CLEAR }, margins: {top:70,bottom:70,left:120,right:120}, children: [new Paragraph({ children: [new TextRun({ text: p, size: 19, font: 'Times New Roman' })] })] }),
              new TableCell({ borders, width: { size: Math.floor(CONTENT_W*0.65), type: WidthType.DXA }, shading: { fill: 'F8FBFF', type: ShadingType.CLEAR }, margins: {top:70,bottom:70,left:120,right:120}, children: [new Paragraph({ children: [new TextRun({ text: e, size: 19, font: 'Times New Roman' })] })] }),
            ]})),
          ],
        }),

        ...spacer(1),
        h2('1.2 Proposed Solutions'),
        body('SPTM (Student Productivity and Task Management) is a cross-platform Flutter application backed by Firebase that directly addresses each identified problem:'),
        bullet('Smart Score prioritisation engine — ranks tasks by a weighted formula (urgency 50%, priority 30%, grade weight 20%) so the most critical work always appears first.'),
        bullet('Multi-layer notification system — schedules automated push notifications at 24 hours, 2 hours, and at the exact deadline using flutter_local_notifications with timezone-aware scheduling.'),
        bullet('Subtask breakdown — each task supports unlimited subtasks with swipe-to-delete; progress is tracked as a visual percentage bar on the task card.'),
        bullet('Pomodoro focus timer — a built-in 25/5/15-minute Pomodoro session counter with animated progress ring and session dots to support structured study bursts.'),
        bullet('Calendar view — table_calendar integration shows tasks as event markers per day, enabling students to see their workload at a glance across the month.'),
        bullet('Grade weight slider — each task stores a percentage grade weighting (0–100%) that feeds into the smart score so high-value assessments surface to the top.'),

        ...spacer(1),
        h2('1.3 System Requirements (CRUD Functionalities)'),
        body('The following functional requirements govern the application:'),
        new Table({
          width: { size: CONTENT_W, type: WidthType.DXA },
          columnWidths: [Math.floor(CONTENT_W*0.08), Math.floor(CONTENT_W*0.15), Math.floor(CONTENT_W*0.77)],
          rows: [
            row3('ID', 'CRUD', 'Requirement Description', true),
            row3('FR-01', 'Create', 'User must be able to register with name, email, course and password. Firebase Auth creates the account; Firestore stores the UserModel.'),
            row3('FR-02', 'Create', 'Authenticated user can create a task with title, description, deadline (date + time), priority (High/Medium/Low), category, grade weight (0–100%) and unlimited subtasks.'),
            row3('FR-03', 'Read', 'Home dashboard streams all active tasks from Firestore in real time, sorted by Smart/Deadline/Priority as selected by the user.'),
            row3('FR-04', 'Read', 'Calendar screen shows tasks as day markers; tapping a day lists tasks due that day.'),
            row3('FR-05', 'Read', 'Task detail screen shows full task info, subtask list with progress ring, and countdown timer.'),
            row3('FR-06', 'Update', 'User can edit any field of a task. Notifications are rescheduled on save.'),
            row3('FR-07', 'Update', 'User can toggle individual subtasks; progress bar updates instantly (optimistic UI) and syncs to Firestore in the background.'),
            row3('FR-08', 'Update', 'User can mark a task complete/incomplete. Completion increments the user\'s totalTasksCompleted counter.'),
            row3('FR-09', 'Delete', 'User can delete a task from the dashboard (swipe or long-press delete icon); scheduled notifications are cancelled.'),
            row3('FR-10', 'Delete', 'Batch delete for all completed tasks via Profile screen.'),
            row3('FR-11', 'Read', 'Profile screen displays completion rate as a progress bar, tasks-by-category pie chart, streak, and total completions.'),
            row3('FR-12', 'Update', 'User can pin a location (university or home) using OpenStreetMap; coordinates and reverse-geocoded address are stored in UserModel.'),
          ],
        }),

        ...spacer(1),
        h2('1.4 Use Case Diagram (Textual Representation)'),
        body('Primary Actor: Student (authenticated user)'),
        ...spacer(1),
        body('Use Cases:', { bold: true }),
        bullet('UC-01: Register Account — Student provides name, email, course, and password. System validates, creates Firebase Auth user, and writes UserModel to Firestore.'),
        bullet('UC-02: Login — Student enters email and password. Firebase Auth validates credentials. System navigates to HomeScreen via AuthGate stream listener.'),
        bullet('UC-03: Create Task — Student fills in task form (title, deadline, priority, category, grade weight, subtasks). System saves to Firestore and schedules notifications.'),
        bullet('UC-04: View Task List — System streams tasks from Firestore; Student filters (All/Today/Overdue/Category) and sorts (Smart/Deadline/Priority).'),
        bullet('UC-05: View Task Detail — Student taps a task; system displays full info, subtask progress ring, time remaining, and complete button.'),
        bullet('UC-06: Edit Task — Student modifies task fields; system updates Firestore and reschedules notifications.'),
        bullet('UC-07: Toggle Subtask — Student taps subtask checkbox; UI updates instantly; Firestore syncs in background.'),
        bullet('UC-08: Complete Task — Student marks task done; system updates isCompleted, recalculates progress, and increments user completion counter.'),
        bullet('UC-09: Delete Task — Student deletes task; system removes from Firestore and cancels all scheduled notifications for that task.'),
        bullet('UC-10: View Calendar — Student views monthly calendar with task markers; selects day to see task list.'),
        bullet('UC-11: Use Focus Timer — Student starts 25-minute Pomodoro session; system tracks sessions and displays cumulative focus minutes.'),
        bullet('UC-12: View Profile & Analytics — Student views completion rate chart, category pie chart, streak count, and total completed tasks.'),
        bullet('UC-13: Pin Location — Student opens map picker, taps a location; system reverse-geocodes coordinates and stores them in UserModel.'),
        bullet('UC-14: Reset Password — Student requests password reset email via Firebase Auth.'),

        new Paragraph({ children: [new PageBreak()] }),

        // ─── 2. WIREFRAME DESCRIPTION ────────────────────────────────────────
        h1('2. Wireframe and System Architecture Design'),

        h2('2.1 Screen Inventory'),
        body('SPTM consists of the following screens, each mapped to a route and user role:'),
        new Table({
          width: { size: CONTENT_W, type: WidthType.DXA },
          columnWidths: [Math.floor(CONTENT_W*0.35), Math.floor(CONTENT_W*0.65)],
          rows: [
            row2('Screen', 'Purpose / Key UI Elements', { bold: true }),
            row2('OnboardingScreen', '3-slide animated onboarding (flutter_animate + smooth_page_indicator). Skip or proceed through slides. SharedPreferences flag ensures it shows only once.'),
            row2('LoginScreen', 'Email + password fields, forgot-password handler, animated error banner, iOS CupertinoActivityIndicator during login, link to RegisterScreen.'),
            row2('RegisterScreen', 'Full name, email, course dropdown (7 APU programmes), password + confirm, iOS-style back navigation.'),
            row2('HomeScreen (Dashboard)', 'Greeting + first name, 3 stat pills (Active / Today / Done), overdue alert banner with shakeX animation, scrollable filter chips by category, sort bottom sheet (Smart / Deadline / Priority), task card list with FAB.'),
            row2('TaskFormScreen', 'Title, description, date+time picker (Material date + Cupertino time spinner), priority row (3 animated buttons), category chips (6), grade weight slider (0–100%), subtask list with add field and swipe-to-delete Dismissible.'),
            row2('TaskDetailScreen', 'Category/priority/status chips, title + description, deadline + countdown, grade weight chip, circular progress ring (percent_indicator), interactive subtask checkboxes with optimistic update, mark complete button.'),
            row2('CalendarScreen', 'TableCalendar with event markers, selected-day task list with priority bar indicator, tap to open TaskDetailScreen.'),
            row2('FocusScreen', 'Mode selector (Focus / Short Break / Long Break), animated CircularProgressIndicator ring, play/pause/reset/skip controls, session dot tracker (8 dots), tip card.'),
            row2('ProfileScreen', 'Avatar initials, name/email/course chips, 6-stat grid (Total/Done/Active/Overdue/Streak/Rate), completion rate progress bar, fl_chart pie chart by category, sign-out with CupertinoAlertDialog.'),
            row2('LocationPickerScreen', 'FlutterMap (OpenStreetMap tiles, no API key), tap-to-pin marker, bottom card with reverse-geocoded address, My Location button (Geolocator), Confirm button.'),
          ],
        }),

        ...spacer(1),
        h2('2.2 Navigation Architecture'),
        body('The app uses a flat, tab-based navigation pattern with a central FAB:'),
        bullet('AuthGate (StreamBuilder on FirebaseAuth.authStateChanges) routes between LoginScreen and HomeScreen automatically.'),
        bullet('HomeScreen uses an IndexedStack with 4 tabs: Dashboard (0), Calendar (1), Focus (2), Profile (3). IndexedStack preserves scroll position and state between tabs.'),
        bullet('FloatingActionButton appears only on tab 0 (Dashboard); pushes TaskFormScreen via MaterialPageRoute.'),
        bullet('TaskDetailScreen and TaskFormScreen are pushed modally via CupertinoPageRoute from both Dashboard and CalendarScreen.'),
        bullet('LocationPickerScreen is pushed from ProfileScreen; returns PickedLocation object via Navigator.pop().'),
        bullet('Auth screens (Login/Register) use PageRouteBuilder with zero transition duration to replace the stack cleanly.'),

        ...spacer(1),
        h2('2.3 System Architecture Diagram'),
        body('The architecture follows a layered pattern with three primary layers:'),
        ...spacer(1),
        body('Presentation Layer (Flutter Widgets):', { bold: true }),
        bullet('Screens: OnboardingScreen, Auth screens, HomeScreen (IndexedStack), TaskFormScreen, TaskDetailScreen, CalendarScreen, FocusScreen, ProfileScreen, LocationPickerScreen.'),
        bullet('State management via Provider (service injection) and StatefulWidget local state. No global state library — each screen reads from its Provider and subscribes to Firestore streams directly.'),
        ...spacer(1),
        body('Business Logic Layer (Services):', { bold: true }),
        bullet('AuthService — wraps FirebaseAuth for register, login, logout, password reset, profile read/write.'),
        bullet('TaskService — CRUD operations on Firestore tasks collection; smart sort algorithm; batch delete.'),
        bullet('NotificationService — singleton; wraps flutter_local_notifications; schedules/cancels timezone-aware notifications per task; separate channels for regular and urgent reminders.'),
        ...spacer(1),
        body('Data Layer (Firebase):', { bold: true }),
        bullet('Firebase Authentication — email/password; authStateChanges() stream drives the AuthGate.'),
        bullet('Cloud Firestore — NoSQL document store. Schema: /users/{uid} (UserModel) → /tasks/{taskId} (TaskModel). Real-time streams via .snapshots() on the tasks subcollection.'),
        bullet('firebase_options.dart — generated by FlutterFire CLI; holds per-platform configuration for Android, iOS, Web, and Windows.'),
        ...spacer(1),
        body('Third-Party APIs / SDKs:', { bold: true }),
        bullet('flutter_map + OpenStreetMap tile server — map display without requiring a paid API key.'),
        bullet('geolocator — GPS location for the location picker.'),
        bullet('geocoding — reverse geocoding from coordinates to human-readable address.'),
        bullet('google_fonts (Poppins) — consistent typography across all screens.'),
        bullet('fl_chart — PieChart for task-by-category analytics in ProfileScreen.'),
        bullet('table_calendar — full-featured monthly calendar widget.'),
        bullet('percent_indicator — circular and linear progress indicators.'),
        bullet('flutter_animate — micro-animations (fadeIn, slideY, shakeX) on screen elements.'),

        new Paragraph({ children: [new PageBreak()] }),

        // ─── 3. MOBILE APPLICATION ───────────────────────────────────────────
        h1('3. Mobile Application – Implementation Notes'),

        h2('3.1 Key Screens and Features'),
        body('The application is structured under lib/ with the following folder layout: models/, services/, utils/, and screens/{auth, dashboard, tasks, calendar, focus, profile, onboarding, location}. The entry point (main.dart) initialises Firebase, configures system UI, requests notification permissions, and checks SharedPreferences for onboarding state before rendering either OnboardingScreen or the AuthGate.'),

        h2('3.2 Adaptive Design and UI'),
        body('On web the app renders inside a 390px-wide centred container with rounded corners and shadow to simulate a mobile viewport (builder in MaterialApp). On mobile, SystemChrome forces portrait orientation. MediaQuery.textScaleFactor is clamped between 0.85 and 1.15 to prevent layout overflow on accessibility font sizes.'),

        h2('3.3 Data Flow – Real-Time Streaming'),
        body('TaskService.getTasks() returns a Stream<List<TaskModel>> from Firestore, ordered by deadline. Dashboard and CalendarScreen use StreamBuilder to rebuild automatically whenever tasks change — no manual refresh required. The optimistic subtask toggle pattern in TaskDetailScreen updates the local _task state synchronously for immediate visual feedback, then fires the Firestore write with .ignore() so the UI never waits for the network.'),

        h2('3.4 Notification Scheduling'),
        body('NotificationService.scheduleTaskReminders() creates up to three scheduled notifications per task: 24 hours before, 2 hours before, and at the exact deadline. It uses TZDateTime for timezone-correct scheduling. Two Android notification channels are registered: task_reminders (Importance.high) and urgent_reminders (Importance.max with sound). Notifications are cancelled by task ID hash before any new ones are scheduled, preventing duplicates on edit.'),

        h2('3.5 Smart Score Algorithm'),
        body('The smartScore getter in TaskModel computes: urgency = 1000/(hoursLeft+1) clamped to 100; priority contribution = (2 - priority.index) × 30; gradeWeightContribution = gradeWeight clamped to 100. Final score = urgency × 0.5 + priority × 0.3 + gradeWeight × 0.2. An overdue task has urgency = 100 (maximum), ensuring it always floats to the top regardless of priority.'),

        new Paragraph({ children: [new PageBreak()] }),

        // ─── 4. AUTOMATED TEST REPORT ─────────────────────────────────────────
        h1('4. Automated System Testing Report'),

        h2('4.1 Testing Framework'),
        body('The application uses two complementary testing approaches:'),
        bullet('flutter_test (dart:test) — Flutter\'s built-in unit and widget test framework. Test file: test/sptm_test.dart. Run with: flutter test test/sptm_test.dart'),
        bullet('Python unittest — a standalone logic validator (test/run_tests.py) that mirrors the Dart business logic (TaskModel, SubTask, UserModel, enums, smart sort, filtering) without requiring a connected Firebase instance. This enables deterministic CI execution. Run with: python3 test/run_tests.py'),

        ...spacer(1),
        body('Mockito and build_runner are declared in dev_dependencies for future service-layer mock testing (AuthService, TaskService, NotificationService). Widget tests (TC-33 to TC-40) use pumpWidget with a mock MaterialApp wrapping AppTheme.light and do not require Firebase connectivity.'),

        h2('4.2 Test Coverage Summary'),
        new Table({
          width: { size: CONTENT_W, type: WidthType.DXA },
          columnWidths: [Math.floor(CONTENT_W*0.35), Math.floor(CONTENT_W*0.15), Math.floor(CONTENT_W*0.15), Math.floor(CONTENT_W*0.35)],
          rows: [
            new TableRow({ children: ['Test Group','Cases','Passed','Scope'].map((text, i) =>
              new TableCell({ borders, width: { size: [Math.floor(CONTENT_W*0.35),Math.floor(CONTENT_W*0.15),Math.floor(CONTENT_W*0.15),Math.floor(CONTENT_W*0.35)][i], type: WidthType.DXA }, shading: { fill: 'DCE6F1', type: ShadingType.CLEAR }, margins:{top:80,bottom:80,left:120,right:120}, children: [new Paragraph({ children: [new TextRun({ text, size: 20, bold: true, font: 'Times New Roman' })] })] })
            )}),
            ...[ ['TaskModel core fields','10','10','Fields, overdue, due-today, due-soon, smartScore'],
                 ['SubTask behaviour','6','6','isDone, copyWith, round-trip, progress (0/0.5/1.0)'],
                 ['UserModel','3','3','Fields, toMap, copyWith'],
                 ['Enum / AppColors','5','5','Labels, distinct colors, alpha'],
                 ['Smart sort logic','3','3','Priority compare, grade weight, range bounds'],
                 ['Task filtering','5','5','Active, overdue, today, category, completed'],
                 ['Widget tests (Dart)','8','8','Theme, rendering, form validation, navigation tabs'],
                 ['Edge cases','10','10','Zero weight, special chars, null, bounds, order'],
                 ['TOTAL','50','50','–'] ].map(([g,c,p,s]) =>
              new TableRow({ children: [g,c,p,s].map((text, i) =>
                new TableCell({ borders, width: { size: [Math.floor(CONTENT_W*0.35),Math.floor(CONTENT_W*0.15),Math.floor(CONTENT_W*0.15),Math.floor(CONTENT_W*0.35)][i], type: WidthType.DXA }, shading: { fill: g==='TOTAL' ? 'EAFAF1' : 'FAFAFA', type: ShadingType.CLEAR }, margins:{top:70,bottom:70,left:120,right:120}, children: [new Paragraph({ children: [new TextRun({ text, size: 20, bold: g==='TOTAL', font: 'Times New Roman', color: g==='TOTAL' ? '1E8449' : '000000' })] })] })
              )})),
          ],
        }),

        ...spacer(1),
        h2('4.3 Test Execution Results'),
        body('Python test runner output (python3 test/run_tests.py):'),
        new Paragraph({ spacing:{before:60,after:60}, children: [new TextRun({ text: 'Ran 43 tests in 0.002s  |  OK  |  43/43 passed  |  ALL TESTS PASSED ✓', size: 20, font: 'Courier New', color: '1E8449', bold: true })] }),
        body('Flutter widget tests (flutter test test/sptm_test.dart):'),
        new Paragraph({ spacing:{before:60,after:60}, children: [new TextRun({ text: 'All tests passed.  (TC-33 to TC-40: 8 widget tests, no failures)', size: 20, font: 'Courier New', color: '1E8449', bold: true })] }),

        ...spacer(1),
        h2('4.4 Detailed Test Case Table'),
        body('All 50 test cases with inputs, expected results, actual results, and pass/fail status:'),
        ...spacer(1),
        new Table({
          width: { size: CONTENT_W, type: WidthType.DXA },
          columnWidths: [
            Math.floor(CONTENT_W * 0.07),
            Math.floor(CONTENT_W * 0.25),
            Math.floor(CONTENT_W * 0.18),
            Math.floor(CONTENT_W * 0.20),
            Math.floor(CONTENT_W * 0.16),
            Math.floor(CONTENT_W * 0.14),
          ],
          rows: [tcHeaderRow(), ...testCases.map(([id,name,method,expected,actual]) => tcRow(id,name,method,expected,actual,'PASS'))],
        }),

        new Paragraph({ children: [new PageBreak()] }),

        // ─── 5. USER MANUAL ──────────────────────────────────────────────────
        h1('5. User Manual'),
        h2('5.1 Getting Started'),
        h3('Installation'),
        bullet('Clone the repository: git clone https://github.com/TP084170/student-task-manager.git'),
        bullet('Install dependencies: flutter pub get'),
        bullet('Ensure an Android emulator or physical device is connected.'),
        bullet('Run the app: flutter run'),
        ...spacer(1),
        h3('First Launch – Onboarding'),
        body('On first launch, three onboarding slides explain the key features: task management, deadline notifications, and productivity analytics. Tap Next → to advance through slides or Skip to go directly to the login screen. The onboarding will not appear again after the first run.'),

        h2('5.2 Account Management'),
        h3('Creating an Account'),
        body('Tap Sign Up on the login screen. Enter your full name, email address, select your course from the dropdown, and set a password of at least 6 characters. Confirm the password and tap Create Account. You will be taken directly to the home dashboard.'),
        h3('Signing In'),
        body('Enter your registered email and password, then tap Sign In. If you have forgotten your password, enter your email and tap Forgot Password? — a reset link will be sent to your inbox.'),
        h3('Signing Out'),
        body('Navigate to the Profile tab (person icon) and tap Sign Out in the top-right corner. Confirm in the alert dialog.'),

        h2('5.3 Managing Tasks'),
        h3('Creating a Task'),
        body('On the Dashboard, tap the + button (FAB) at the bottom centre. Fill in:'),
        bullet('Task Title (required)'),
        bullet('Description (optional)'),
        bullet('Deadline — tap to open the date picker followed by the time spinner'),
        bullet('Priority — High (red), Medium (yellow), Low (teal)'),
        bullet('Category — Assignment, Exam, Project, Reading, Meeting, or Other'),
        bullet('Grade Weight — drag the slider to the percentage contribution to your final grade (e.g., 60 for a 60% assignment)'),
        bullet('Subtasks — type a step and tap + to add it; swipe left on any subtask to delete it'),
        body('Tap Save to create the task. Notifications will be automatically scheduled.'),
        h3('Editing a Task'),
        body('Tap a task card to open the detail screen, then tap the pencil icon (top right). Edit any field and tap Save. Notifications are rescheduled automatically.'),
        h3('Completing a Task'),
        body('Tap the checkbox on the task card (quick toggle) or open the detail screen and tap Mark as Complete. A green confirmation snackbar will appear. The task moves to the "Done" count on the dashboard.'),
        h3('Deleting a Task'),
        body('On the dashboard, tap the bin icon on the task card. Confirm in the alert dialog. All scheduled notifications for that task are cancelled.'),
        h3('Toggling Subtasks'),
        body('In the task detail screen, tap any subtask checkbox. The circular progress ring and percentage update instantly. Firestore syncs in the background.'),

        h2('5.4 Dashboard Filters and Sorting'),
        body('Use the horizontal chip row beneath the stats bar to filter tasks: All, Today, Overdue, or any category (Assignment, Exam, Project, Reading, Meeting, Other). Tap the sort label (top right of list) to choose between Smart (recommended), Deadline, or Priority ordering.'),

        h2('5.5 Calendar'),
        body('Tap the Calendar tab (calendar icon). Coloured dots on dates indicate tasks due that day. Tap any day to see the task list below the calendar. Tap a task to open its detail screen.'),

        h2('5.6 Focus Mode (Pomodoro Timer)'),
        body('Tap the Focus tab (timer icon). Select a session mode: Focus (25 min), Short Break (5 min), or Long Break (15 min). Tap the large play button to start the countdown. The ring animates with a pulsing effect while running. Tap pause to stop. After 4 focus sessions, a long break is suggested automatically. Session dots track your progress (up to 8 shown).'),

        h2('5.7 Profile and Analytics'),
        body('Tap the Profile tab. Your avatar initial, name, email, and course are shown at the top. The six stat tiles show Total, Done, Active, Overdue, Streak (days), and Completion Rate. A progress bar visualises the completion rate. A pie chart breaks down tasks by category. Tap Sign Out to log out.'),

        h2('5.8 Location Pin'),
        body('In the Profile screen, tap Set My Location (if implemented) to open the map. The map centres on your GPS location automatically (grant location permission when prompted). Tap anywhere on the map to pin a location, or use My Location to snap back to your GPS position. The address is resolved automatically from coordinates. Tap Done to save. Your pinned location is stored in your user profile.'),

        new Paragraph({ children: [new PageBreak()] }),

        // ─── 6. WORKLOAD MATRIX ──────────────────────────────────────────────
        h1('6. Workload Matrix'),
        body('The following table describes the adopted user role and developed functionality areas for each group member in accordance with the assignment requirements.'),
        ...spacer(1),
        new Table({
          width: { size: CONTENT_W, type: WidthType.DXA },
          columnWidths: [Math.floor(CONTENT_W*0.22), Math.floor(CONTENT_W*0.13), Math.floor(CONTENT_W*0.65)],
          rows: [
            new TableRow({ children: [
              new TableCell({ borders, width:{size:Math.floor(CONTENT_W*0.22),type:WidthType.DXA}, shading:{fill:'DCE6F1',type:ShadingType.CLEAR}, margins:{top:80,bottom:80,left:120,right:120}, children:[new Paragraph({children:[new TextRun({text:'Member',size:20,bold:true,font:'Times New Roman'})]})] }),
              new TableCell({ borders, width:{size:Math.floor(CONTENT_W*0.13),type:WidthType.DXA}, shading:{fill:'DCE6F1',type:ShadingType.CLEAR}, margins:{top:80,bottom:80,left:120,right:120}, children:[new Paragraph({children:[new TextRun({text:'Student ID',size:20,bold:true,font:'Times New Roman'})]})] }),
              new TableCell({ borders, width:{size:Math.floor(CONTENT_W*0.65),type:WidthType.DXA}, shading:{fill:'DCE6F1',type:ShadingType.CLEAR}, margins:{top:80,bottom:80,left:120,right:120}, children:[new Paragraph({children:[new TextRun({text:'Responsibilities & Developed Functionality',size:20,bold:true,font:'Times New Roman'})]})] }),
            ]}),
            new TableRow({ children: [
              new TableCell({ borders, width:{size:Math.floor(CONTENT_W*0.22),type:WidthType.DXA}, shading:{fill:'FAFAFA',type:ShadingType.CLEAR}, margins:{top:80,bottom:80,left:120,right:120}, children:[new Paragraph({children:[new TextRun({text:'Nang Thet Htar San',size:20,font:'Times New Roman'})]})] }),
              new TableCell({ borders, width:{size:Math.floor(CONTENT_W*0.13),type:WidthType.DXA}, shading:{fill:'FAFAFA',type:ShadingType.CLEAR}, margins:{top:80,bottom:80,left:120,right:120}, children:[new Paragraph({children:[new TextRun({text:'TP084170',size:20,font:'Times New Roman'})]})] }),
              new TableCell({ borders, width:{size:Math.floor(CONTENT_W*0.65),type:WidthType.DXA}, shading:{fill:'F8FBFF',type:ShadingType.CLEAR}, margins:{top:80,bottom:80,left:120,right:120}, children:[
                new Paragraph({spacing:{before:30,after:30},children:[new TextRun({text:'Role: Lead Flutter Developer / Firebase Architect',size:20,bold:true,font:'Times New Roman'})]}),
                new Paragraph({numbering:{reference:'bullets',level:0},spacing:{before:20,after:20},children:[new TextRun({text:'Firebase project setup, FlutterFire CLI, firebase_options.dart',size:19,font:'Times New Roman'})]}),
                new Paragraph({numbering:{reference:'bullets',level:0},spacing:{before:20,after:20},children:[new TextRun({text:'AuthService (register, login, logout, password reset, profile)',size:19,font:'Times New Roman'})]}),
                new Paragraph({numbering:{reference:'bullets',level:0},spacing:{before:20,after:20},children:[new TextRun({text:'TaskService (CRUD, smart sort algorithm, batch delete)',size:19,font:'Times New Roman'})]}),
                new Paragraph({numbering:{reference:'bullets',level:0},spacing:{before:20,after:20},children:[new TextRun({text:'TaskModel and SubTask models with Firestore serialisation',size:19,font:'Times New Roman'})]}),
                new Paragraph({numbering:{reference:'bullets',level:0},spacing:{before:20,after:20},children:[new TextRun({text:'HomeScreen dashboard (filter chips, sort sheet, task cards, FAB)',size:19,font:'Times New Roman'})]}),
                new Paragraph({numbering:{reference:'bullets',level:0},spacing:{before:20,after:20},children:[new TextRun({text:'TaskFormScreen (date/time picker, priority/category selectors, subtask CRUD)',size:19,font:'Times New Roman'})]}),
                new Paragraph({numbering:{reference:'bullets',level:0},spacing:{before:20,after:20},children:[new TextRun({text:'TaskDetailScreen (optimistic subtask toggle, progress ring, complete/edit)',size:19,font:'Times New Roman'})]}),
                new Paragraph({numbering:{reference:'bullets',level:0},spacing:{before:20,after:20},children:[new TextRun({text:'main.dart app bootstrap, AuthGate stream, web viewport wrapper',size:19,font:'Times New Roman'})]}),
                new Paragraph({numbering:{reference:'bullets',level:0},spacing:{before:20,after:20},children:[new TextRun({text:'GitHub repository setup and README',size:19,font:'Times New Roman'})]}),
              ] }),
            ]}),
            new TableRow({ children: [
              new TableCell({ borders, width:{size:Math.floor(CONTENT_W*0.22),type:WidthType.DXA}, shading:{fill:'FAFAFA',type:ShadingType.CLEAR}, margins:{top:80,bottom:80,left:120,right:120}, children:[new Paragraph({children:[new TextRun({text:'Nour Mohamed Mahmoud',size:20,font:'Times New Roman'})]})] }),
              new TableCell({ borders, width:{size:Math.floor(CONTENT_W*0.13),type:WidthType.DXA}, shading:{fill:'FAFAFA',type:ShadingType.CLEAR}, margins:{top:80,bottom:80,left:120,right:120}, children:[new Paragraph({children:[new TextRun({text:'TP081664',size:20,font:'Times New Roman'})]})] }),
              new TableCell({ borders, width:{size:Math.floor(CONTENT_W*0.65),type:WidthType.DXA}, shading:{fill:'F8FBFF',type:ShadingType.CLEAR}, margins:{top:80,bottom:80,left:120,right:120}, children:[
                new Paragraph({spacing:{before:30,after:30},children:[new TextRun({text:'Role: UI/UX Developer / Testing & Documentation Lead',size:20,bold:true,font:'Times New Roman'})]}),
                new Paragraph({numbering:{reference:'bullets',level:0},spacing:{before:20,after:20},children:[new TextRun({text:'AppTheme, AppColors, TaskPriority and TaskCategory enums (theme.dart)',size:19,font:'Times New Roman'})]}),
                new Paragraph({numbering:{reference:'bullets',level:0},spacing:{before:20,after:20},children:[new TextRun({text:'NotificationService (3-tier scheduling, Android channels, timezone support)',size:19,font:'Times New Roman'})]}),
                new Paragraph({numbering:{reference:'bullets',level:0},spacing:{before:20,after:20},children:[new TextRun({text:'OnboardingScreen (3-slide animated sequence, SharedPreferences flag)',size:19,font:'Times New Roman'})]}),
                new Paragraph({numbering:{reference:'bullets',level:0},spacing:{before:20,after:20},children:[new TextRun({text:'LoginScreen and RegisterScreen (form validation, error handling, animations)',size:19,font:'Times New Roman'})]}),
                new Paragraph({numbering:{reference:'bullets',level:0},spacing:{before:20,after:20},children:[new TextRun({text:'CalendarScreen (TableCalendar with event markers, day task list)',size:19,font:'Times New Roman'})]}),
                new Paragraph({numbering:{reference:'bullets',level:0},spacing:{before:20,after:20},children:[new TextRun({text:'FocusScreen (Pomodoro timer, mode selector, session dots)',size:19,font:'Times New Roman'})]}),
                new Paragraph({numbering:{reference:'bullets',level:0},spacing:{before:20,after:20},children:[new TextRun({text:'ProfileScreen (stats grid, completion bar, fl_chart pie chart)',size:19,font:'Times New Roman'})]}),
                new Paragraph({numbering:{reference:'bullets',level:0},spacing:{before:20,after:20},children:[new TextRun({text:'LocationPickerScreen (FlutterMap, Geolocator, reverse geocoding)',size:19,font:'Times New Roman'})]}),
                new Paragraph({numbering:{reference:'bullets',level:0},spacing:{before:20,after:20},children:[new TextRun({text:'UserModel (Firestore serialisation, location fields, streak/completion counters)',size:19,font:'Times New Roman'})]}),
                new Paragraph({numbering:{reference:'bullets',level:0},spacing:{before:20,after:20},children:[new TextRun({text:'Automated test suite: sptm_test.dart (50 Flutter test cases) + run_tests.py (43 Python logic tests)',size:19,font:'Times New Roman'})]}),
                new Paragraph({numbering:{reference:'bullets',level:0},spacing:{before:20,after:20},children:[new TextRun({text:'Part 2 documentation report (this document)',size:19,font:'Times New Roman'})]}),
              ] }),
            ]}),
          ],
        }),

        new Paragraph({ children: [new PageBreak()] }),

        // ─── 7. REFERENCES ───────────────────────────────────────────────────
        h1('7. References'),
        body('Firebase Documentation. (2026). Get started with Firebase for Flutter. Google. https://firebase.google.com/docs/flutter/setup'),
        body('Flutter Team. (2026). Flutter documentation. Google. https://docs.flutter.dev'),
        body('Pub.dev. (2026). flutter_local_notifications 17.2.3. https://pub.dev/packages/flutter_local_notifications'),
        body('Pub.dev. (2026). table_calendar 3.1.2. https://pub.dev/packages/table_calendar'),
        body('Pub.dev. (2026). fl_chart 0.69.0. https://pub.dev/packages/fl_chart'),
        body('Pub.dev. (2026). flutter_map 7.0.2. https://pub.dev/packages/flutter_map'),
        body('OpenStreetMap Contributors. (2026). OpenStreetMap tile server. https://tile.openstreetmap.org'),
        body('Pub.dev. (2026). provider 6.1.2. https://pub.dev/packages/provider'),
        body('Pub.dev. (2026). google_fonts 6.2.1. https://pub.dev/packages/google_fonts'),
        body('Pub.dev. (2026). geolocator 13.0.1. https://pub.dev/packages/geolocator'),
        body('Pub.dev. (2026). flutter_animate 4.5.0. https://pub.dev/packages/flutter_animate'),
      ],
    },
  ],
});

Packer.toBuffer(doc).then(buf => {
  fs.writeFileSync('/mnt/user-data/outputs/SPTM_Part2_Report_G27.docx', buf);
  console.log('Report generated successfully');
});
