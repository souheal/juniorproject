<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // ما عم نغيّر شي قديم، بس عم نضيف عمود جديد Nullable
            $table->string('last_login_ip', 45)->nullable()->after('email_verification_token');
            // لو ما عندك email_verification_token حط after('email_verified_at')
            // $table->string('last_login_ip', 45)->nullable()->after('email_verified_at');
        });
    }
    

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('last_login_ip');
        });
    }
};
