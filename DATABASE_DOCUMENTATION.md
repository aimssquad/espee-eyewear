# Journal Submission and Review System Database Documentation

## Overview
This MySQL database schema is designed for a comprehensive journal submission and peer review system. It supports multiple authors, journals, editors, and reviewers with full chat message history and revision tracking capabilities.

## Key Features
- **Multi-role User System**: Authors, Editors, Reviewers, and Admins
- **Multiple Journal Support**: Each journal can have multiple editors
- **Flexible Assignment System**: Multiple editors and reviewers per submission
- **Complete Chat History**: Full communication tracking between all parties
- **Revision Tracking**: Support for multiple revision rounds
- **Status History**: Complete audit trail of all status changes
- **Rejection and Resubmission**: Papers can be rejected and come back again

## Database Tables

### 1. Users Table
**Purpose**: Stores all system users (authors, editors, reviewers, admins)

**Key Fields**:
- `user_id`: Primary key
- `email`: Unique identifier for login
- `user_type`: ENUM('author', 'editor', 'reviewer', 'admin')
- `expertise_areas`: JSON/text field for matching reviewers

### 2. Journals Table
**Purpose**: Stores journal information

**Key Fields**:
- `journal_id`: Primary key
- `journal_code`: Unique short code (e.g., "JCSR")
- `subject_areas`: Topics covered by the journal

### 3. Journal_Editors Table
**Purpose**: Many-to-many relationship between journals and editors

**Key Fields**:
- `role`: ENUM('chief_editor', 'associate_editor', 'guest_editor')
- Supports multiple editors per journal

### 4. Submissions Table
**Purpose**: Core table for manuscript submissions

**Key Fields**:
- `manuscript_id`: Human-readable ID (e.g., "JNL-2024-001")
- `current_status`: Tracks submission through workflow
- `current_round`: Supports multiple revision rounds
- `manuscript_file_path`: File storage location

**Status Flow**:
```
submitted → under_initial_review → assigned_to_reviewers → 
under_peer_review → revision_requested → revised_submitted → 
accepted/rejected
```

### 5. Submission_History Table
**Purpose**: Complete audit trail of all status changes

**Key Features**:
- Tracks every status transition
- Records who made the change and when
- Supports comments for each change
- Links to revision rounds

### 6. Submission_Editors Table
**Purpose**: Many-to-many relationship for editor assignments

**Key Features**:
- Multiple editors can be assigned to one submission
- Different editor roles supported
- Assignment status tracking

### 7. Submission_Reviewers Table
**Purpose**: Manages reviewer assignments and reviews

**Key Features**:
- Multiple reviewers per submission
- Review status tracking (invited → accepted → in_progress → completed)
- Recommendation types (accept, minor_revision, major_revision, reject)
- Due date tracking
- Separate fields for public and confidential comments

### 8. Chat_Messages Table
**Purpose**: Complete communication history

**Key Features**:
- Messages between any parties (author-editor, editor-reviewer, etc.)
- Message types for categorization
- Read status tracking
- Attachment support
- System-generated messages
- Round-based message organization

## Key Relationships

### One-to-Many Relationships
- User → Submissions (author)
- Journal → Submissions
- Submission → History records
- Submission → Chat messages

### Many-to-Many Relationships
- Journals ↔ Editors (via journal_editors)
- Submissions ↔ Editors (via submission_editors)
- Submissions ↔ Reviewers (via submission_reviewers)

## Important Features

### 1. Revision Support
The system supports multiple revision rounds:
- `current_round` field in submissions table
- `review_round` field in reviewers table
- `round_number` in history table
- `message_round` in chat messages

### 2. Rejection and Resubmission
- Papers can be rejected and resubmitted
- Full history is maintained
- New submission can reference previous attempts

### 3. Flexible Communication
- Direct messages between specific users
- Broadcast messages to all parties
- System-generated notifications
- Message categorization by type

### 4. Performance Optimization
- Strategic indexes on frequently queried fields
- Views for common query patterns
- Efficient foreign key relationships

## Common Use Cases

### 1. Author Dashboard
```sql
-- Get all submissions for an author
SELECT manuscript_id, title, current_status, submission_date 
FROM submissions 
WHERE author_id = ?
```

### 2. Editor Workload
```sql
-- Get all active assignments for an editor
SELECT s.manuscript_id, s.title, s.current_status
FROM submissions s
JOIN submission_editors se ON s.submission_id = se.submission_id
WHERE se.editor_id = ? AND se.assignment_status = 'active'
```

### 3. Reviewer Dashboard
```sql
-- Get pending reviews for a reviewer
SELECT s.manuscript_id, s.title, sr.due_date
FROM submission_reviewers sr
JOIN submissions s ON sr.submission_id = s.submission_id
WHERE sr.reviewer_id = ? AND sr.review_status IN ('accepted', 'in_progress')
```

### 4. Communication History
```sql
-- Get all messages for a submission
SELECT sender_name, message_content, sent_date
FROM chat_messages cm
JOIN users u ON cm.sender_id = u.user_id
WHERE cm.submission_id = ?
ORDER BY sent_date
```

## Security Considerations

### 1. Access Control
- Role-based access through `user_type` field
- Submission-specific permissions via assignments
- Confidential reviewer comments separated

### 2. Data Integrity
- Foreign key constraints maintain referential integrity
- ENUM fields prevent invalid status values
- Unique constraints prevent duplicates

### 3. Audit Trail
- Complete history tracking in submission_history
- Timestamp fields on all critical actions
- User tracking for all changes

## Scalability Features

### 1. Indexing Strategy
- Composite indexes for common query patterns
- Date-based indexes for time-range queries
- Status indexes for filtering

### 2. File Storage
- File paths stored as strings (actual files stored separately)
- JSON fields for multiple file attachments
- Scalable file organization structure

### 3. Performance Views
- Pre-built views for complex queries
- Aggregated statistics views
- Common dashboard queries optimized

## Installation Instructions

1. **Create Database**:
```sql
CREATE DATABASE journal_system CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE journal_system;
```

2. **Run Schema**:
```bash
mysql -u username -p journal_system < journal_system_database.sql
```

3. **Load Sample Data** (optional):
```bash
mysql -u username -p journal_system < sample_data_and_queries.sql
```

## Extension Points

The schema is designed to be extensible:

1. **Additional User Types**: Easily add new user roles
2. **Custom Fields**: JSON fields allow for flexible metadata
3. **Workflow Customization**: Status enums can be modified
4. **Integration Ready**: Clean API-friendly structure
5. **Reporting**: Views and indexes support complex reporting

This database schema provides a solid foundation for a full-featured journal submission and review system with room for customization and growth.