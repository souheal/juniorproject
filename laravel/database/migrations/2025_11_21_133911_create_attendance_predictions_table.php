<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('attendance_predictions', function (Blueprint $table) {
            $table->bigIncrements('id');

            $table->foreignId('event_id')
                  ->constrained('events')
                  ->cascadeOnDelete();

            $table->integer('predicted_attendance')->nullable(false);
            $table->decimal('predicted_fill_ratio', 5, 2)->nullable(); // e.g. 0.75

            $table->string('risk_level', 20)->nullable(false); // 'low', 'medium', 'high'
            $table->string('model_version', 50)->nullable(false); // e.g. 'v1.0-rf'

            $table->timestamp('predicted_at')
                  ->default(DB::raw('CURRENT_TIMESTAMP'));

            // Optional actual performance fields
            $table->integer('actual_attendance')->nullable();
            $table->integer('absolute_error')->nullable();
            $table->decimal('percentage_error', 5, 2)->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('attendance_predictions');
    }
};
