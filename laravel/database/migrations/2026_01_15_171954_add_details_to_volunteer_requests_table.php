<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('volunteer_requests', function (Blueprint $table) {
            // Applicant-provided information
            $table->text('availability')->nullable()->after('volunteer_type');
            $table->text('previous_experience')->nullable()->after('availability');
            $table->json('social_links')->nullable()->after('previous_experience'); // array of URLs
            $table->text('skills')->nullable()->after('social_links');
            $table->text('added_value')->nullable()->after('skills'); // what they add
        });
    }

    public function down(): void
    {
        Schema::table('volunteer_requests', function (Blueprint $table) {
            $table->dropColumn([
                'availability',
                'previous_experience',
                'social_links',
                'skills',
                'added_value',
            ]);
        });
    }
};
