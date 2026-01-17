<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\OrganizerProfile;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class OrganizerProfileController extends Controller
{
    public function show(Request $request)
    {
        $user = $request->user()->load('organizerProfile');

        $profile = $user->organizerProfile;

        if (!$profile) {
            $profile = OrganizerProfile::create([
                'user_id' => $user->id,
                'verified' => false,
                'contact_email' => $user->email,
            ]);
        }

        return response()->json([
            'profile' => $this->formatProfile($profile),
        ]);
    }

    public function update(Request $request)
    {
        $user = $request->user();

        $profile = OrganizerProfile::firstOrCreate(
            ['user_id' => $user->id],
            ['contact_email' => $user->email, 'verified' => false]
        );

        $data = $request->validate([
            'organization_name' => 'required|string|max:255',
            'description'       => 'required|string|max:5000',

            'contact_email'     => 'required|email|max:255',
            'contact_phone'     => 'nullable|string|max:50',

            'website'           => 'nullable|url|max:255',
            'facebook'          => 'nullable|string|max:255',
            'instagram'         => 'nullable|string|max:255',
            'twitter'           => 'nullable|string|max:255',

            // base64 image string or null (to delete)
            'logo'              => 'nullable|string',
        ]);

        // handle logo (base64)
        if (array_key_exists('logo', $data)) {
            if ($data['logo']) {
                if ($profile->logo && Storage::disk('public')->exists($profile->logo)) {
                    Storage::disk('public')->delete($profile->logo);
                }
                $profile->logo = $this->storeBase64Image($data['logo'], 'organizers');
            } else {
                if ($profile->logo && Storage::disk('public')->exists($profile->logo)) {
                    Storage::disk('public')->delete($profile->logo);
                }
                $profile->logo = null;
            }
            unset($data['logo']);
        }

        $profile->fill($data);
        $profile->save();

        return response()->json([
            'message' => 'Organizer profile updated successfully.',
            'profile' => $this->formatProfile($profile->fresh()),
        ]);
    }

    private function formatProfile(OrganizerProfile $profile): array
    {
        return [
            'id' => $profile->id,
            'user_id' => $profile->user_id,

            'organization_name' => $profile->organization_name,
            'description' => $profile->description,

            'contact_email' => $profile->contact_email,
            'contact_phone' => $profile->contact_phone,

            'website' => $profile->website,
            'facebook' => $profile->facebook,
            'instagram' => $profile->instagram,
            'twitter' => $profile->twitter,

            'verified' => (bool) $profile->verified,

            'logo' => $profile->logo ? asset('storage/' . $profile->logo) : null,
        ];
    }

    protected function storeBase64Image(string $base64, string $folder): string
    {
        if (preg_match('/^data:image\/(\w+);base64,/', $base64, $type)) {
            $base64 = substr($base64, strpos($base64, ',') + 1);
            $extension = strtolower($type[1]) === 'jpeg' ? 'jpg' : $type[1];
        } else {
            $extension = 'png';
        }

        $binary = base64_decode($base64, true);

        if ($binary === false) {
            abort(422, 'Invalid image data.');
        }

        $fileName = $folder . '/' . uniqid('', true) . '.' . $extension;
        Storage::disk('public')->put($fileName, $binary);

        return $fileName;
    }
}
