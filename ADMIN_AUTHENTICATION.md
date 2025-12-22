# Eventy Admin Authentication System

## Overview
The Eventy platform uses a **single admin account** system for maximum security. Only ONE admin account exists and can access the admin dashboard.

## Security Features

### 1. Single Admin Account
- **Only ONE admin account** can exist in the system
- Created via database seeder (not through registration)
- Admin account details:
  - **Email**: `admin@eventy.com`
  - **Default Password**: `Admin@123` ⚠️ **CHANGE IMMEDIATELY**

### 2. Registration Protection
- ✅ Admin accounts **CANNOT** be created through registration
- ✅ All registrations are automatically assigned the 'user' role
- ✅ Attempts to specify role during registration are rejected with 400 error

### 3. Role-Based Access Control
- **user** - Regular users (browse events, buy tickets, volunteer)
- **organizer** - Event creators (manage events, scan tickets)
- **admin** - Platform administrator (ONE account only)

### 4. Admin Route Protection
All admin routes are protected by TWO layers:
1. **Authentication** (`auth:sanctum`) - Must be logged in
2. **Authorization** (`admin` middleware) - Must have admin role

## Admin Account Setup

### First Time Setup

1. **Run the Admin Seeder** (creates the admin account):
```bash
cd laravel
php artisan db:seed --class=AdminSeeder
```

Output:
```
✅ Admin account created successfully!
Email: admin@eventy.com
Password: Admin@123
⚠️  IMPORTANT: Change the password immediately after first login!
```

2. **Login to Admin Dashboard**:
- Navigate to the React admin dashboard
- Login with:
  - Email: `admin@eventy.com`
  - Password: `Admin@123`

3. **Change Password Immediately**:
- After first login, change the password via profile settings

### Re-running the Seeder

If you run the seeder again:
```bash
php artisan db:seed --class=AdminSeeder
```

Output:
```
⚠️ Admin account already exists: admin@eventy.com
```

The seeder prevents creating duplicate admin accounts.

## Protected Admin Routes

All routes under `/api/admin/*` require admin role:

### Organizer Management
```
GET    /api/admin/organizer-requests              - List all organizer requests
POST   /api/admin/organizer-requests/{id}/approve - Approve organizer request
POST   /api/admin/organizer-requests/{id}/reject  - Reject organizer request
```

### Event Management
```
DELETE /api/admin/events/{id}                     - Delete event (admin only)
```

## API Response Codes

### 401 Unauthorized
```json
{
  "message": "Unauthenticated. Please log in."
}
```
**Reason**: No authentication token provided or token expired

### 403 Forbidden
```json
{
  "message": "Access denied. Admin privileges required."
}
```
**Reason**: User is authenticated but not an admin

### 400 Bad Request (Registration)
```json
{
  "message": "Invalid registration attempt. User roles cannot be specified during registration."
}
```
**Reason**: Attempted to create admin account via registration

## Middleware Details

### EnsureUserIsAdmin Middleware

Location: `app/Http/Middleware/EnsureUserIsAdmin.php`

**What it does**:
1. Checks if user is authenticated
2. Loads user's role
3. Verifies role name is exactly 'admin'
4. Returns 403 if not admin, allows request if admin

**Applied to**:
- All routes in `Route::prefix('admin')->middleware('admin')`

## Security Best Practices

### ✅ DO:
- Change default admin password immediately after first login
- Use strong passwords (minimum 12 characters, mixed case, numbers, symbols)
- Log admin actions for audit trail
- Regularly review admin access logs

### ❌ DON'T:
- Share admin credentials with anyone
- Use the default password in production
- Attempt to create admin accounts through registration API
- Remove the admin middleware from admin routes
- Manually change user roles to admin without proper authorization

## Testing the System

### Test 1: Admin Login (Should Succeed)
```bash
curl -X POST http://10.74.241.124:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@eventy.com",
    "password": "Admin@123"
  }'
```

Expected Response:
```json
{
  "message": "Login successful",
  "user": {
    "id": 1,
    "name": "Eventy Admin",
    "email": "admin@eventy.com",
    "role": {
      "id": 3,
      "name": "admin"
    }
  },
  "token": "1|..."
}
```

### Test 2: Access Admin Route (Should Succeed with Admin Token)
```bash
curl -X GET http://10.74.241.124:8000/api/admin/organizer-requests \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Accept: application/json"
```

### Test 3: Access Admin Route as Non-Admin (Should Fail)
```bash
# Login as regular user first, then try admin endpoint
curl -X GET http://10.74.241.124:8000/api/admin/organizer-requests \
  -H "Authorization: Bearer USER_TOKEN" \
  -H "Accept: application/json"
```

Expected Response:
```json
{
  "message": "Access denied. Admin privileges required."
}
```

### Test 4: Attempt to Register as Admin (Should Fail)
```bash
curl -X POST http://10.74.241.124:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "fake-admin@test.com",
    "password": "password123",
    "password_confirmation": "password123",
    "role": "admin",
    "name": "Fake Admin",
    "phone": "1234567890",
    "location": "Test",
    "birth_date": "1990-01-01"
  }'
```

Expected Response:
```json
{
  "message": "Invalid registration attempt. User roles cannot be specified during registration."
}
```

## Troubleshooting

### Problem: "Admin role not found" when running seeder
**Solution**: Run the RoleSeeder first
```bash
php artisan db:seed --class=RoleSeeder
php artisan db:seed --class=AdminSeeder
```

### Problem: Forgot admin password
**Solution**: Reset via database
```bash
php artisan tinker
```
```php
$admin = \App\Models\User::where('email', 'admin@eventy.com')->first();
$admin->password = \Illuminate\Support\Facades\Hash::make('NewPassword123');
$admin->save();
```

### Problem: Admin account deleted accidentally
**Solution**: Re-run the seeder
```bash
php artisan db:seed --class=AdminSeeder
```

### Problem: Getting 401 instead of 403 for non-admin users
**Solution**: Check that user is logged in and token is valid

## Architecture

### Database Schema
```
users
  ├── id (PK)
  ├── role_id (FK to roles)
  ├── email (unique)
  ├── password (hashed)
  └── ... other fields

roles
  ├── id (PK)
  └── name (user/organizer/admin)
```

### Authentication Flow
```
1. User submits login (email + password)
2. Backend validates credentials
3. Backend generates Sanctum token
4. Frontend stores token
5. Frontend includes token in Authorization header for all requests
6. Backend validates token (auth:sanctum middleware)
7. Backend validates role (admin middleware for admin routes)
8. Request processed if authorized
```

## Files Modified/Created

### Created:
- `database/seeders/AdminSeeder.php` - Creates single admin account
- `app/Http/Middleware/EnsureUserIsAdmin.php` - Admin authorization middleware

### Modified:
- `routes/api.php` - Added admin middleware to admin routes
- `bootstrap/app.php` - Registered admin middleware alias
- `app/Http/Controllers/Api/AuthController.php` - Added registration protection

## Production Checklist

Before deploying to production:

- [ ] Change default admin password
- [ ] Review all admin route protections
- [ ] Enable HTTPS for all API requests
- [ ] Set up rate limiting for login attempts
- [ ] Configure proper CORS settings
- [ ] Enable API logging for admin actions
- [ ] Set up monitoring/alerting for unauthorized access attempts
- [ ] Regular security audits of admin access
- [ ] Backup admin credentials securely

## Support

For security issues or questions about admin access, contact the development team immediately.

---

**Last Updated**: December 2025
**System Version**: Eventy v1.0
**Backend**: Laravel 12.0 + Sanctum
**Frontend**: React Admin Dashboard
