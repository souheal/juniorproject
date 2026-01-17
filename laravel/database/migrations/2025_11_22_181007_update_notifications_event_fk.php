<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('notifications', function (Blueprint $table) {
            // 1) فكّ القيود القديمة على event_id
            $table->dropForeign(['event_id']); 

            // 2) نضمن إنها قابلة للـ NULL
            $table->unsignedBigInteger('event_id')->nullable()->change();

            // 3) نرجع نضيف foreign key بدون cascade, مع nullOnDelete
            $table->foreign('event_id')
                ->references('id')
                ->on('events')
                ->nullOnDelete();  
        });
    }

    public function down(): void
    {
        Schema::table('notifications', function (Blueprint $table) {
            // نرجّع الوضع القديم
            $table->dropForeign(['event_id']);

            $table->unsignedBigInteger('event_id')->nullable(false)->change();

            $table->foreign('event_id')
                ->references('id')
                ->on('events')
                ->onDelete('cascade');
        });
    }
};
