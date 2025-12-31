<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('organizer_profiles', function (Blueprint $table) {
            $table->string('organization_name')->nullable()->after('organization_category_id');
            $table->text('description')->nullable()->after('organization_name');

            $table->string('contact_email')->nullable()->after('description');
            $table->text('contact_phone')->nullable()->after('contact_email'); // text for encryption-safe length

            $table->string('logo')->nullable()->after('contact_phone');

            $table->string('facebook')->nullable()->after('logo');
            $table->string('instagram')->nullable()->after('facebook');
            $table->string('twitter')->nullable()->after('instagram');
        });
    }

    public function down(): void
    {
        Schema::table('organizer_profiles', function (Blueprint $table) {
            $table->dropColumn([
                'organization_name',
                'description',
                'contact_email',
                'contact_phone',
                'logo',
                'facebook',
                'instagram',
                'twitter',
            ]);
        });
    }
};
