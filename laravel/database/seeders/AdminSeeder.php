<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use App\Models\User;
use App\Models\Role;

class AdminSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * Creates ONE admin account for the Eventy platform.
     * This is the ONLY admin account that should ever exist.
     */
    public function run(): void
    {
        // Get admin role
        $adminRole = Role::where('name', 'admin')->first();

        if (!$adminRole) {
            $this->command->error('Admin role not found. Please run RoleSeeder first.');
            return;
        }

        // Check if admin already exists
        $existingAdmin = User::where('role_id', $adminRole->id)->first();

        if ($existingAdmin) {
            $this->command->warn('Admin account already exists: ' . $existingAdmin->email);
            return;
        }

        // Create the SINGLE admin account
        $admin = User::create([
            'role_id' => $adminRole->id,
            'name' => 'Eventy Admin',
            'email' => 'admin@eventy.com',
            'password' => Hash::make('Admin@123'), // Change this password!
            'phone' => '+1234567890',
            'location' => 'Admin Office',
            'email_verified_at' => now(),
            'notifications_enabled' => true,
        ]);

        $this->command->info('✅ Admin account created successfully!');
        $this->command->info('Email: admin@eventy.com');
        $this->command->warn('Password: Admin@123');
        $this->command->warn('⚠️  IMPORTANT: Change the password immediately after first login!');
    }
}
