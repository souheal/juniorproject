<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('events', function (Blueprint $table) {
            // status with default 'draft'
            $table->string('status', 20)
                  ->default('draft')
                  ->nullable(false);

            // when event was published
            $table->timestamp('published_at')->nullable();

            // city of event (optional for now)
            $table->string('city', 255)->nullable();
        });

        // Add CHECK constraint for status (PostgreSQL)
        DB::statement("
            ALTER TABLE events
            ADD CONSTRAINT events_status_check
            CHECK (status IN ('draft', 'published', 'cancelled', 'completed'))
        ");
    }

    public function down(): void
    {
        // Drop the CHECK constraint first
        DB::statement("ALTER TABLE events DROP CONSTRAINT IF EXISTS events_status_check");

        Schema::table('events', function (Blueprint $table) {
            $table->dropColumn(['status', 'published_at', 'city']);
        });
    }
};
