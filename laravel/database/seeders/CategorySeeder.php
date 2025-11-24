<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Category;

class CategorySeeder extends Seeder
{
    public function run(): void
    {
        $names = [
            
            'Music',
            'Concert',
            'Comedy',
            'Theatre',
            'Festival',
            'Art Exhibition',
            'Sports',
            'Gaming Event',

            'IT',
            'Business',
            'Conference',
            'Startup Pitch',
            'Hackathon',
            'Workshop',
            'Education',

            'Discussion',
            'Debate',
            'Community',
            'Charity',
            'Book Fair',
        ];

        foreach ($names as $name) {
            Category::firstOrCreate(['name' => $name]);
        }
    }
}
