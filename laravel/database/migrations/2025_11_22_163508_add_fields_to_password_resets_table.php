<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
   public function up(): void
{
    Schema::table('password_resets', function (Blueprint $table) {
        // Only add these if they don't already exist
        $table->string('email')->after('user_id');
        $table->string('code')->after('email');
        $table->timestamp('expires_at')->after('code');
    });
}

public function down(): void
{
    Schema::table('password_resets', function (Blueprint $table) {
        $table->dropColumn(['email', 'code', 'expires_at']);
    });
}

};
