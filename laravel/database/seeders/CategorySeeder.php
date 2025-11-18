<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Category;

class CategorySeeder extends Seeder
{
    public function run(): void
    {
        $names = [
            'Information Technology',
            'Doctor',
            'Engineering',
            'Education',
            'Finance & Accounting',
            'Media & Marketing',
            'Hospitality',
            'Construction',
            'Student',
            'Other',
        ];

        foreach ($names as $name) {
            Category::firstOrCreate(['name' => $name]);
        }
    }
}
