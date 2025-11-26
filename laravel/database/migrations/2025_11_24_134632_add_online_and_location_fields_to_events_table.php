<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('events', function (Blueprint $table) {

            // new sub-location fields
            $table->string('venue')->nullable()->after('city'); // e.g. Four Seasons Hotel

            
            $table->boolean('is_live')->default(false)->after('end_datetime');
            // or: $table->boolean('is_online')->default(false);
        });
    }

    public function down(): void
    {
        Schema::table('events', function (Blueprint $table) {
            $table->dropColumn(['venue', 'is_live']); 
        });
    }
};
