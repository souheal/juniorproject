<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('organizer_requests', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');

            $table->string('organization_name');   // إجباري
            $table->text('description');          // إجباري (ما في ->nullable())

            $table->string('documents')->nullable(); // ممكن يرفع ملف أو لأ

            $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending');

            $table->text('admin_comment')->nullable();

            $table->timestamps();

        // خيار تصميم: طلب واحد لكل يوزر
            $table->unique('user_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('organizer_requests');
    }
};
