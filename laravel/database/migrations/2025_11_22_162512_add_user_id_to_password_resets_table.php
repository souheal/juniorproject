<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('password_resets', function (Blueprint $table) {
            // Add the user_id column and make it a foreign key to users.id
            $table->foreignId('user_id')
                ->after('id') // assuming the table has an id column
                ->constrained('users')
                ->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('password_resets', function (Blueprint $table) {
            // Drop the foreign key + column if we rollback
            $table->dropConstrainedForeignId('user_id');
            // If dropConstrainedForeignId complains in your Laravel version, use:
            // $table->dropForeign(['user_id']);
            // $table->dropColumn('user_id');
        });
    }
};
