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
            $table->dropForeign(['event_id']); // Laravel يترجمها لاسم الفوريجن الصحيح

            // 2) نضمن إنها قابلة للـ NULL (احتياطاً)
            $table->unsignedBigInteger('event_id')->nullable()->change();

            // 3) نرجع نضيف foreign key بدون cascade, مع nullOnDelete
            $table->foreign('event_id')
                ->references('id')
                ->on('events')
                ->nullOnDelete();  // 👈 هون السحر: ما بقا cascade delete
        });
    }

    public function down(): void
    {
        Schema::table('notifications', function (Blueprint $table) {
            // نرجّع الوضع القديم (لو حبيت ترجع)
            $table->dropForeign(['event_id']);

            $table->unsignedBigInteger('event_id')->nullable(false)->change();

            $table->foreign('event_id')
                ->references('id')
                ->on('events')
                ->onDelete('cascade');
        });
    }
};
