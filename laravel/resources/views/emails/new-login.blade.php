@component('mail::message')
# New Login Detected

Hello {{ $user->name }},

A new login to your account was detected.

- **Current IP:** {{ $currentIp }}
@if($previousIp)
- **Previous IP:** {{ $previousIp }}
@else
- This is the first recorded login for this account.
@endif

If this was you, no further action is needed.  
If you do not recognize this activity, please change your password immediately.

Thanks,  
**JuniorProject Team**
@endcomponent
