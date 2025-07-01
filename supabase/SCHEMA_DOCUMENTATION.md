# Database Schema Documentation

This document provides a comprehensive overview of the database schema for the Jhonny Family Task Management App with Virtual Pet System.

## Overview

The database schema is designed to support a family-based task management system with gamified virtual pet mechanics. The schema is fully aligned with the domain entities and follows clean architecture principles.

## Schema Structure

### Core Tables

#### 1. **profiles** - User Management
Stores user account information and family associations.

```sql
CREATE TABLE profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  role user_role NOT NULL,  -- 'parent' or 'child'
  family_id UUID REFERENCES families(id),
  last_login_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);
```

**Key Features:**
- Links to Supabase auth.users with CASCADE delete
- Role-based access (parent/child)
- Family association for multi-user families
- Metadata field for extensible user data
- Automatic timestamp management

#### 2. **families** - Family Management
Manages family groups and member relationships.

```sql
CREATE TABLE families (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  invite_code TEXT UNIQUE NOT NULL,  -- 6-character code
  created_by_id UUID REFERENCES profiles(id) NOT NULL,
  parent_ids UUID[] DEFAULT '{}',    -- Array of parent user IDs
  child_ids UUID[] DEFAULT '{}',     -- Array of child user IDs
  last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  settings JSONB DEFAULT '{}',       -- Family preferences
  metadata JSONB DEFAULT '{}',       -- Extensible data
  pet_image_url TEXT,                -- Current family pet image
  pet_stage_images JSONB DEFAULT '{}', -- Stage-specific images
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);
```

**Key Features:**
- Unique 6-character invite codes for family joining
- Array-based member management (parent_ids, child_ids)
- Activity tracking for engagement metrics
- Pet image management at family level
- Flexible settings and metadata storage

#### 3. **tasks** - Task Management
Handles family task assignment, completion, and verification.

```sql
CREATE TABLE tasks (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  points INTEGER NOT NULL CHECK (points >= 0),
  family_id UUID REFERENCES families(id) NOT NULL,
  assigned_to_id UUID REFERENCES profiles(id) NOT NULL,
  created_by_id UUID REFERENCES profiles(id) NOT NULL,
  status task_status NOT NULL DEFAULT 'pending', -- 'pending', 'inProgress', 'completed', 'expired'
  frequency task_frequency NOT NULL,             -- 'once', 'daily', 'weekly', 'monthly'
  due_date TIMESTAMP WITH TIME ZONE NOT NULL,
  verified_by_id UUID REFERENCES profiles(id),  -- Parent who verified completion
  verified_at TIMESTAMP WITH TIME ZONE,
  image_urls TEXT[] DEFAULT '{}',               -- Proof of completion images
  metadata JSONB DEFAULT '{}',                  -- Additional task data
  is_archived BOOLEAN NOT NULL DEFAULT FALSE,   -- Soft delete flag
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  completed_at TIMESTAMP WITH TIME ZONE
);
```

**Key Features:**
- Point-based reward system
- Multi-status workflow (pending → inProgress → completed)
- Parent verification system for task completion
- Recurring task support (daily, weekly, monthly)
- Multiple image attachments per task
- Soft deletion with archiving
- Comprehensive audit trail

#### 4. **pets** - Virtual Pet System
Manages virtual pets with evolution and care mechanics.

```sql
CREATE TABLE pets (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  owner_id UUID REFERENCES profiles(id) NOT NULL,
  family_id UUID REFERENCES families(id) NOT NULL,
  mood pet_mood NOT NULL DEFAULT 'neutral',      -- 'happy', 'content', 'neutral', 'sad', 'upset'
  stage pet_stage NOT NULL DEFAULT 'egg',        -- 'egg', 'baby', 'child', 'teen', 'adult'
  experience INTEGER NOT NULL DEFAULT 0 CHECK (experience >= 0),
  level INTEGER NOT NULL DEFAULT 1 CHECK (level >= 1),
  happiness INTEGER NOT NULL DEFAULT 50 CHECK (happiness >= 0 AND happiness <= 100),
  energy INTEGER NOT NULL DEFAULT 100 CHECK (energy >= 0 AND energy <= 100),
  health INTEGER NOT NULL DEFAULT 100 CHECK (health >= 0 AND health <= 100),
  last_fed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  last_played_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);
```

**Key Features:**
- Evolution system (egg → baby → child → teen → adult)
- Dynamic mood calculation based on care and neglect
- Triple stat system (happiness, energy, health)
- Experience-based progression
- Care tracking (feeding, playing)
- Automatic stat decay over time

### Enums

#### user_role
```sql
CREATE TYPE user_role AS ENUM ('parent', 'child');
```

#### task_status
```sql
CREATE TYPE task_status AS ENUM ('pending', 'inProgress', 'completed', 'expired');
```

#### task_frequency
```sql
CREATE TYPE task_frequency AS ENUM ('once', 'daily', 'weekly', 'monthly');
```

#### pet_mood
```sql
CREATE TYPE pet_mood AS ENUM ('happy', 'content', 'neutral', 'sad', 'upset');
```

#### pet_stage
```sql
CREATE TYPE pet_stage AS ENUM ('egg', 'baby', 'child', 'teen', 'adult');
```

## Storage Buckets

### task_images
- **Purpose**: Store task completion proof images
- **Access**: Family members only
- **Public**: No

### profile_images
- **Purpose**: Store user avatar images
- **Access**: Public read access
- **Public**: Yes

### pet_images
- **Purpose**: Store pet stage images and family pet customizations
- **Access**: Public read access
- **Public**: Yes

## Key Features

### 1. Row Level Security (RLS)
All tables have comprehensive RLS policies that ensure:
- Users can only access data from their own family
- Parents have additional privileges for task verification
- Children can only manage their own pets and assigned tasks

### 2. Automatic Triggers
- **Timestamp Updates**: All tables automatically update `updated_at` on changes
- **Family Activity Tracking**: Updates `last_activity_at` when family members perform actions
- **Invite Code Generation**: Automatically generates unique 6-character invite codes
- **Pet Mood Calculation**: Automatically updates pet mood based on care stats
- **Pet Evolution**: Triggers evolution when experience thresholds are met

### 3. Performance Optimization
- **Indexes**: Comprehensive indexing strategy for common query patterns
- **Composite Indexes**: Optimized for family-based queries and active task filtering
- **Partial Indexes**: Special indexes for non-archived records

### 4. Data Integrity
- **Foreign Key Constraints**: Ensure referential integrity
- **Check Constraints**: Validate data ranges (points ≥ 0, stats 0-100, etc.)
- **Unique Constraints**: Prevent duplicate invite codes and emails

## Utility Functions

### Pet Care Functions
- `calculate_pet_mood()`: Calculates pet mood based on stats and care history
- `can_pet_evolve()`: Checks if pet has enough experience to evolve
- `evolve_pet()`: Handles pet evolution to next stage

### Task Management Functions
- `get_user_task_stats()`: Returns comprehensive task completion statistics
- `archive_expired_tasks()`: Automatically archives old expired tasks

### Family Management Functions
- `add_family_member()`: Adds a user to a family with specified role
- `remove_family_member()`: Removes a user from a family
- `user_can_access_family()`: Security check for family data access
- `user_is_family_parent()`: Role verification for parent-only actions

### Maintenance Functions
- `daily_maintenance()`: Performs scheduled maintenance tasks
- `generate_unique_invite_code()`: Creates unique family invite codes

## Helpful Views

### family_member_details
Provides detailed information about family members with task statistics.

### pet_family_details
Shows pet information combined with family and owner details.

## Migration Strategy

The schema includes three main migration files:

1. **20241203000000_align_schemas_with_domain.sql** - Aligns database with domain entities
2. **20241203000001_add_utility_functions.sql** - Adds application logic functions
3. **schema.sql** - Complete unified schema for new installations

## Security Considerations

1. **Authentication**: Integrates with Supabase Auth
2. **Authorization**: Role-based access with RLS policies
3. **Data Isolation**: Family-based data segregation
4. **Audit Trail**: Comprehensive timestamp and user tracking
5. **Soft Deletes**: Important data is archived, not deleted

## Scalability Features

1. **Efficient Indexing**: Optimized for common access patterns
2. **Array Storage**: Efficient member management without junction tables
3. **JSONB Metadata**: Flexible schema extension without migrations
4. **Realtime Support**: Real-time updates for collaborative features
5. **Modular Design**: Easy to extend with new features

## Future Considerations

The schema is designed to be extensible for future features:
- Additional pet types and customizations
- Advanced task categories and difficulty levels
- Achievement and badge systems
- Family competition and leaderboards
- Notification and reminder systems

This schema provides a solid foundation for the family task management system while maintaining performance, security, and extensibility. 