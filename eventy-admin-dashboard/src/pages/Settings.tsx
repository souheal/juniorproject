import {
  Settings as SettingsIcon,
  Save,
  Bell,
  Shield,
  Globe,
  Users,
  Calendar,
  CreditCard,
  Palette,
  AlertCircle,
  Check,
} from 'lucide-react';
import { useState } from 'react';

type SettingsTab = 'general' | 'users' | 'events' | 'notifications' | 'security' | 'payments' | 'appearance';

interface SettingsState {
  // General
  platformName: string;
  platformDescription: string;
  supportEmail: string;
  timezone: string;
  dateFormat: string;
  language: string;

  // Users
  allowRegistration: boolean;
  requireEmailVerification: boolean;
  allowSocialLogin: boolean;
  autoApproveOrganizers: boolean;
  maxEventsPerOrganizer: number;

  // Events
  requireEventApproval: boolean;
  allowEventComments: boolean;
  allowEventRatings: boolean;
  maxTicketsPerUser: number;
  eventExpiryDays: number;

  // Notifications
  emailNotifications: boolean;
  newOrganizerAlert: boolean;
  newEventAlert: boolean;
  flaggedContentAlert: boolean;
  dailyReportEmail: boolean;
  weeklyReportEmail: boolean;

  // Security
  sessionTimeout: number;
  maxLoginAttempts: number;
  lockoutDuration: number;
  requireStrongPassword: boolean;
  twoFactorAuth: boolean;

  // Payments
  currency: string;
  platformCommission: number;
  minWithdrawal: number;
  paymentMethods: string[];

  // Appearance
  primaryColor: string;
  darkMode: boolean;
  showLogo: boolean;
  maintenanceMode: boolean;
}

export function Settings() {
  const [activeTab, setActiveTab] = useState<SettingsTab>('general');
  const [isSaving, setIsSaving] = useState(false);
  const [saveSuccess, setSaveSuccess] = useState(false);

  const [settings, setSettings] = useState<SettingsState>({
    // General
    platformName: 'Eventy',
    platformDescription: 'Your ultimate event management platform',
    supportEmail: 'support@eventy.com',
    timezone: 'Asia/Damascus',
    dateFormat: 'DD/MM/YYYY',
    language: 'en',

    // Users
    allowRegistration: true,
    requireEmailVerification: true,
    allowSocialLogin: false,
    autoApproveOrganizers: false,
    maxEventsPerOrganizer: 50,

    // Events
    requireEventApproval: false,
    allowEventComments: true,
    allowEventRatings: true,
    maxTicketsPerUser: 10,
    eventExpiryDays: 30,

    // Notifications
    emailNotifications: true,
    newOrganizerAlert: true,
    newEventAlert: true,
    flaggedContentAlert: true,
    dailyReportEmail: false,
    weeklyReportEmail: true,

    // Security
    sessionTimeout: 60,
    maxLoginAttempts: 5,
    lockoutDuration: 30,
    requireStrongPassword: true,
    twoFactorAuth: false,

    // Payments
    currency: 'SYP',
    platformCommission: 5,
    minWithdrawal: 50000,
    paymentMethods: ['cash', 'bank_transfer'],

    // Appearance
    primaryColor: '#3B82F6',
    darkMode: false,
    showLogo: true,
    maintenanceMode: false,
  });

  const handleSave = async () => {
    setIsSaving(true);
    setSaveSuccess(false);

    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 1000));

    // TODO: Implement actual save logic
    console.log('Saving settings:', settings);

    setIsSaving(false);
    setSaveSuccess(true);

    // Hide success message after 3 seconds
    setTimeout(() => setSaveSuccess(false), 3000);
  };

  const updateSetting = <K extends keyof SettingsState>(key: K, value: SettingsState[K]) => {
    setSettings((prev) => ({ ...prev, [key]: value }));
  };

  const tabs = [
    { key: 'general' as const, label: 'General', icon: Globe },
    { key: 'users' as const, label: 'Users', icon: Users },
    { key: 'events' as const, label: 'Events', icon: Calendar },
    { key: 'notifications' as const, label: 'Notifications', icon: Bell },
    { key: 'security' as const, label: 'Security', icon: Shield },
    { key: 'payments' as const, label: 'Payments', icon: CreditCard },
    { key: 'appearance' as const, label: 'Appearance', icon: Palette },
  ];

  const Toggle = ({ enabled, onChange, label, description }: { enabled: boolean; onChange: (val: boolean) => void; label: string; description?: string }) => (
    <div className="flex items-center justify-between py-4 border-b border-gray-100 last:border-0">
      <div className="flex-1">
        <p className="font-medium text-gray-900">{label}</p>
        {description && <p className="text-sm text-gray-500 mt-0.5">{description}</p>}
      </div>
      <button
        type="button"
        onClick={() => onChange(!enabled)}
        className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
          enabled ? 'bg-blue-600' : 'bg-gray-200'
        }`}
      >
        <span
          className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
            enabled ? 'translate-x-6' : 'translate-x-1'
          }`}
        />
      </button>
    </div>
  );

  const InputField = ({ label, value, onChange, type = 'text', placeholder, description, suffix }: {
    label: string;
    value: string | number;
    onChange: (val: string) => void;
    type?: string;
    placeholder?: string;
    description?: string;
    suffix?: string;
  }) => (
    <div className="py-4 border-b border-gray-100 last:border-0">
      <label className="block text-sm font-medium text-gray-900 mb-1">{label}</label>
      {description && <p className="text-sm text-gray-500 mb-2">{description}</p>}
      <div className="relative">
        <input
          type={type}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder={placeholder}
          className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
        />
        {suffix && (
          <span className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 text-sm">
            {suffix}
          </span>
        )}
      </div>
    </div>
  );

  const SelectField = ({ label, value, onChange, options, description }: {
    label: string;
    value: string;
    onChange: (val: string) => void;
    options: { value: string; label: string }[];
    description?: string;
  }) => (
    <div className="py-4 border-b border-gray-100 last:border-0">
      <label className="block text-sm font-medium text-gray-900 mb-1">{label}</label>
      {description && <p className="text-sm text-gray-500 mb-2">{description}</p>}
      <select
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white"
      >
        {options.map((opt) => (
          <option key={opt.value} value={opt.value}>{opt.label}</option>
        ))}
      </select>
    </div>
  );

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Settings</h1>
          <p className="text-gray-500 mt-1">Manage your platform settings and preferences</p>
        </div>

        {/* Save Button */}
        <button
          type="button"
          onClick={handleSave}
          disabled={isSaving}
          className="flex items-center px-6 py-2.5 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed shadow-sm"
        >
          {isSaving ? (
            <>
              <div className="animate-spin rounded-full h-4 w-4 border-2 border-white border-t-transparent mr-2" />
              Saving...
            </>
          ) : (
            <>
              <Save className="w-4 h-4 mr-2" />
              Save Changes
            </>
          )}
        </button>
      </div>

      {/* Success Alert */}
      {saveSuccess && (
        <div className="bg-green-50 border border-green-200 rounded-lg p-4 flex items-center gap-3">
          <Check className="w-5 h-5 text-green-600" />
          <p className="text-sm text-green-800">Settings saved successfully!</p>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        {/* Sidebar */}
        <div className="lg:col-span-1">
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-2">
            <nav className="space-y-1">
              {tabs.map((tab) => {
                const Icon = tab.icon;
                return (
                  <button
                    key={tab.key}
                    type="button"
                    onClick={() => setActiveTab(tab.key)}
                    className={`
                      w-full flex items-center px-4 py-3 rounded-lg text-sm font-medium transition-colors
                      ${activeTab === tab.key
                        ? 'bg-blue-50 text-blue-600'
                        : 'text-gray-700 hover:bg-gray-50'
                      }
                    `}
                  >
                    <Icon className="w-5 h-5 mr-3" />
                    {tab.label}
                  </button>
                );
              })}
            </nav>
          </div>

          {/* Warning Card */}
          {settings.maintenanceMode && (
            <div className="mt-4 bg-yellow-50 border border-yellow-200 rounded-xl p-4">
              <div className="flex items-start gap-3">
                <AlertCircle className="w-5 h-5 text-yellow-600 flex-shrink-0 mt-0.5" />
                <div>
                  <p className="text-sm font-medium text-yellow-800">Maintenance Mode Active</p>
                  <p className="text-xs text-yellow-600 mt-1">Users cannot access the platform</p>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Content */}
        <div className="lg:col-span-3">
          <div className="bg-white rounded-xl shadow-sm border border-gray-200">
            {/* General Settings */}
            {activeTab === 'general' && (
              <div className="p-6">
                <div className="flex items-center gap-3 mb-6">
                  <div className="p-2 bg-blue-100 rounded-lg">
                    <Globe className="w-5 h-5 text-blue-600" />
                  </div>
                  <div>
                    <h2 className="text-lg font-semibold text-gray-900">General Settings</h2>
                    <p className="text-sm text-gray-500">Basic platform configuration</p>
                  </div>
                </div>

                <div className="space-y-2">
                  <InputField
                    label="Platform Name"
                    value={settings.platformName}
                    onChange={(val) => updateSetting('platformName', val)}
                    description="The name displayed across the platform"
                  />
                  <InputField
                    label="Platform Description"
                    value={settings.platformDescription}
                    onChange={(val) => updateSetting('platformDescription', val)}
                    description="A short description of your platform"
                  />
                  <InputField
                    label="Support Email"
                    value={settings.supportEmail}
                    onChange={(val) => updateSetting('supportEmail', val)}
                    type="email"
                    description="Email address for user support inquiries"
                  />
                  <SelectField
                    label="Timezone"
                    value={settings.timezone}
                    onChange={(val) => updateSetting('timezone', val)}
                    options={[
                      { value: 'Asia/Damascus', label: 'Damascus (GMT+3)' },
                      { value: 'Asia/Beirut', label: 'Beirut (GMT+2)' },
                      { value: 'Europe/London', label: 'London (GMT+0)' },
                      { value: 'America/New_York', label: 'New York (GMT-5)' },
                    ]}
                    description="Default timezone for events and dates"
                  />
                  <SelectField
                    label="Date Format"
                    value={settings.dateFormat}
                    onChange={(val) => updateSetting('dateFormat', val)}
                    options={[
                      { value: 'DD/MM/YYYY', label: 'DD/MM/YYYY (31/12/2025)' },
                      { value: 'MM/DD/YYYY', label: 'MM/DD/YYYY (12/31/2025)' },
                      { value: 'YYYY-MM-DD', label: 'YYYY-MM-DD (2025-12-31)' },
                    ]}
                  />
                  <SelectField
                    label="Default Language"
                    value={settings.language}
                    onChange={(val) => updateSetting('language', val)}
                    options={[
                      { value: 'en', label: 'English' },
                      { value: 'ar', label: 'Arabic' },
                    ]}
                  />
                </div>
              </div>
            )}

            {/* Users Settings */}
            {activeTab === 'users' && (
              <div className="p-6">
                <div className="flex items-center gap-3 mb-6">
                  <div className="p-2 bg-green-100 rounded-lg">
                    <Users className="w-5 h-5 text-green-600" />
                  </div>
                  <div>
                    <h2 className="text-lg font-semibold text-gray-900">User Settings</h2>
                    <p className="text-sm text-gray-500">Configure user registration and permissions</p>
                  </div>
                </div>

                <div className="space-y-2">
                  <Toggle
                    enabled={settings.allowRegistration}
                    onChange={(val) => updateSetting('allowRegistration', val)}
                    label="Allow User Registration"
                    description="Allow new users to create accounts"
                  />
                  <Toggle
                    enabled={settings.requireEmailVerification}
                    onChange={(val) => updateSetting('requireEmailVerification', val)}
                    label="Require Email Verification"
                    description="Users must verify their email before accessing the platform"
                  />
                  <Toggle
                    enabled={settings.allowSocialLogin}
                    onChange={(val) => updateSetting('allowSocialLogin', val)}
                    label="Allow Social Login"
                    description="Enable login with Google, Facebook, etc."
                  />
                  <Toggle
                    enabled={settings.autoApproveOrganizers}
                    onChange={(val) => updateSetting('autoApproveOrganizers', val)}
                    label="Auto-Approve Organizers"
                    description="Automatically approve organizer applications without review"
                  />
                  <InputField
                    label="Max Events Per Organizer"
                    value={settings.maxEventsPerOrganizer}
                    onChange={(val) => updateSetting('maxEventsPerOrganizer', parseInt(val) || 0)}
                    type="number"
                    description="Maximum number of active events an organizer can have (0 for unlimited)"
                  />
                </div>
              </div>
            )}

            {/* Events Settings */}
            {activeTab === 'events' && (
              <div className="p-6">
                <div className="flex items-center gap-3 mb-6">
                  <div className="p-2 bg-purple-100 rounded-lg">
                    <Calendar className="w-5 h-5 text-purple-600" />
                  </div>
                  <div>
                    <h2 className="text-lg font-semibold text-gray-900">Event Settings</h2>
                    <p className="text-sm text-gray-500">Configure event creation and management</p>
                  </div>
                </div>

                <div className="space-y-2">
                  <Toggle
                    enabled={settings.requireEventApproval}
                    onChange={(val) => updateSetting('requireEventApproval', val)}
                    label="Require Event Approval"
                    description="Events must be approved by admin before being published"
                  />
                  <Toggle
                    enabled={settings.allowEventComments}
                    onChange={(val) => updateSetting('allowEventComments', val)}
                    label="Allow Event Comments"
                    description="Users can leave comments on events"
                  />
                  <Toggle
                    enabled={settings.allowEventRatings}
                    onChange={(val) => updateSetting('allowEventRatings', val)}
                    label="Allow Event Ratings"
                    description="Users can rate events after attending"
                  />
                  <InputField
                    label="Max Tickets Per User"
                    value={settings.maxTicketsPerUser}
                    onChange={(val) => updateSetting('maxTicketsPerUser', parseInt(val) || 1)}
                    type="number"
                    description="Maximum tickets a single user can purchase per event"
                  />
                  <InputField
                    label="Event Expiry Days"
                    value={settings.eventExpiryDays}
                    onChange={(val) => updateSetting('eventExpiryDays', parseInt(val) || 30)}
                    type="number"
                    description="Days after event ends before it's archived"
                    suffix="days"
                  />
                </div>
              </div>
            )}

            {/* Notifications Settings */}
            {activeTab === 'notifications' && (
              <div className="p-6">
                <div className="flex items-center gap-3 mb-6">
                  <div className="p-2 bg-yellow-100 rounded-lg">
                    <Bell className="w-5 h-5 text-yellow-600" />
                  </div>
                  <div>
                    <h2 className="text-lg font-semibold text-gray-900">Notification Settings</h2>
                    <p className="text-sm text-gray-500">Configure admin notifications and alerts</p>
                  </div>
                </div>

                <div className="space-y-2">
                  <Toggle
                    enabled={settings.emailNotifications}
                    onChange={(val) => updateSetting('emailNotifications', val)}
                    label="Email Notifications"
                    description="Receive notifications via email"
                  />
                  <Toggle
                    enabled={settings.newOrganizerAlert}
                    onChange={(val) => updateSetting('newOrganizerAlert', val)}
                    label="New Organizer Requests"
                    description="Get notified when new organizers apply"
                  />
                  <Toggle
                    enabled={settings.newEventAlert}
                    onChange={(val) => updateSetting('newEventAlert', val)}
                    label="New Event Created"
                    description="Get notified when events are created"
                  />
                  <Toggle
                    enabled={settings.flaggedContentAlert}
                    onChange={(val) => updateSetting('flaggedContentAlert', val)}
                    label="Flagged Content"
                    description="Get notified about reported or flagged content"
                  />
                  <Toggle
                    enabled={settings.dailyReportEmail}
                    onChange={(val) => updateSetting('dailyReportEmail', val)}
                    label="Daily Report Email"
                    description="Receive a daily summary of platform activity"
                  />
                  <Toggle
                    enabled={settings.weeklyReportEmail}
                    onChange={(val) => updateSetting('weeklyReportEmail', val)}
                    label="Weekly Report Email"
                    description="Receive a weekly summary of platform statistics"
                  />
                </div>
              </div>
            )}

            {/* Security Settings */}
            {activeTab === 'security' && (
              <div className="p-6">
                <div className="flex items-center gap-3 mb-6">
                  <div className="p-2 bg-red-100 rounded-lg">
                    <Shield className="w-5 h-5 text-red-600" />
                  </div>
                  <div>
                    <h2 className="text-lg font-semibold text-gray-900">Security Settings</h2>
                    <p className="text-sm text-gray-500">Configure security and authentication options</p>
                  </div>
                </div>

                <div className="space-y-2">
                  <InputField
                    label="Session Timeout"
                    value={settings.sessionTimeout}
                    onChange={(val) => updateSetting('sessionTimeout', parseInt(val) || 60)}
                    type="number"
                    description="Time before inactive users are logged out"
                    suffix="minutes"
                  />
                  <InputField
                    label="Max Login Attempts"
                    value={settings.maxLoginAttempts}
                    onChange={(val) => updateSetting('maxLoginAttempts', parseInt(val) || 5)}
                    type="number"
                    description="Maximum failed login attempts before account lockout"
                  />
                  <InputField
                    label="Lockout Duration"
                    value={settings.lockoutDuration}
                    onChange={(val) => updateSetting('lockoutDuration', parseInt(val) || 30)}
                    type="number"
                    description="How long accounts remain locked after too many failed attempts"
                    suffix="minutes"
                  />
                  <Toggle
                    enabled={settings.requireStrongPassword}
                    onChange={(val) => updateSetting('requireStrongPassword', val)}
                    label="Require Strong Passwords"
                    description="Enforce minimum 8 characters with uppercase, lowercase, and numbers"
                  />
                  <Toggle
                    enabled={settings.twoFactorAuth}
                    onChange={(val) => updateSetting('twoFactorAuth', val)}
                    label="Two-Factor Authentication"
                    description="Require 2FA for admin accounts"
                  />
                </div>
              </div>
            )}

            {/* Payments Settings */}
            {activeTab === 'payments' && (
              <div className="p-6">
                <div className="flex items-center gap-3 mb-6">
                  <div className="p-2 bg-emerald-100 rounded-lg">
                    <CreditCard className="w-5 h-5 text-emerald-600" />
                  </div>
                  <div>
                    <h2 className="text-lg font-semibold text-gray-900">Payment Settings</h2>
                    <p className="text-sm text-gray-500">Configure payment and commission options</p>
                  </div>
                </div>

                <div className="space-y-2">
                  <SelectField
                    label="Currency"
                    value={settings.currency}
                    onChange={(val) => updateSetting('currency', val)}
                    options={[
                      { value: 'SYP', label: 'Syrian Pound (SYP)' },
                      { value: 'USD', label: 'US Dollar (USD)' },
                      { value: 'EUR', label: 'Euro (EUR)' },
                    ]}
                    description="Default currency for transactions"
                  />
                  <InputField
                    label="Platform Commission"
                    value={settings.platformCommission}
                    onChange={(val) => updateSetting('platformCommission', parseFloat(val) || 0)}
                    type="number"
                    description="Percentage commission on ticket sales"
                    suffix="%"
                  />
                  <InputField
                    label="Minimum Withdrawal"
                    value={settings.minWithdrawal}
                    onChange={(val) => updateSetting('minWithdrawal', parseInt(val) || 0)}
                    type="number"
                    description="Minimum amount organizers can withdraw"
                    suffix={settings.currency}
                  />

                  <div className="py-4 border-b border-gray-100">
                    <label className="block text-sm font-medium text-gray-900 mb-1">Payment Methods</label>
                    <p className="text-sm text-gray-500 mb-3">Enable payment methods for transactions</p>
                    <div className="space-y-2">
                      {[
                        { value: 'cash', label: 'Cash on Delivery' },
                        { value: 'bank_transfer', label: 'Bank Transfer' },
                        { value: 'credit_card', label: 'Credit Card' },
                        { value: 'mobile_wallet', label: 'Mobile Wallet' },
                      ].map((method) => (
                        <label key={method.value} className="flex items-center">
                          <input
                            type="checkbox"
                            checked={settings.paymentMethods.includes(method.value)}
                            onChange={(e) => {
                              if (e.target.checked) {
                                updateSetting('paymentMethods', [...settings.paymentMethods, method.value]);
                              } else {
                                updateSetting('paymentMethods', settings.paymentMethods.filter((m) => m !== method.value));
                              }
                            }}
                            className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                          />
                          <span className="ml-2 text-sm text-gray-700">{method.label}</span>
                        </label>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Appearance Settings */}
            {activeTab === 'appearance' && (
              <div className="p-6">
                <div className="flex items-center gap-3 mb-6">
                  <div className="p-2 bg-pink-100 rounded-lg">
                    <Palette className="w-5 h-5 text-pink-600" />
                  </div>
                  <div>
                    <h2 className="text-lg font-semibold text-gray-900">Appearance Settings</h2>
                    <p className="text-sm text-gray-500">Customize the look and feel of the platform</p>
                  </div>
                </div>

                <div className="space-y-2">
                  <div className="py-4 border-b border-gray-100">
                    <label className="block text-sm font-medium text-gray-900 mb-1">Primary Color</label>
                    <p className="text-sm text-gray-500 mb-2">Main brand color used across the platform</p>
                    <div className="flex items-center gap-3">
                      <input
                        type="color"
                        value={settings.primaryColor}
                        onChange={(e) => updateSetting('primaryColor', e.target.value)}
                        className="w-12 h-10 rounded border border-gray-300 cursor-pointer"
                      />
                      <input
                        type="text"
                        value={settings.primaryColor}
                        onChange={(e) => updateSetting('primaryColor', e.target.value)}
                        className="w-32 px-3 py-2 border border-gray-300 rounded-lg text-sm uppercase"
                      />
                      <div className="flex gap-2">
                        {['#3B82F6', '#10B981', '#8B5CF6', '#F59E0B', '#EF4444'].map((color) => (
                          <button
                            key={color}
                            type="button"
                            onClick={() => updateSetting('primaryColor', color)}
                            className="w-8 h-8 rounded-full border-2 border-white shadow-md transition-transform hover:scale-110"
                            style={{ backgroundColor: color }}
                          />
                        ))}
                      </div>
                    </div>
                  </div>

                  <Toggle
                    enabled={settings.darkMode}
                    onChange={(val) => updateSetting('darkMode', val)}
                    label="Dark Mode"
                    description="Enable dark mode for the admin dashboard"
                  />
                  <Toggle
                    enabled={settings.showLogo}
                    onChange={(val) => updateSetting('showLogo', val)}
                    label="Show Logo"
                    description="Display platform logo in the header"
                  />
                  <Toggle
                    enabled={settings.maintenanceMode}
                    onChange={(val) => updateSetting('maintenanceMode', val)}
                    label="Maintenance Mode"
                    description="Put the platform in maintenance mode (users cannot access)"
                  />
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
