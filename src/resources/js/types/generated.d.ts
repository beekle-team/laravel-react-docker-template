declare namespace App.Data {
export type CallLogData = {
id: number | null;
company_id: number;
project_id: number;
staff_id: number;
company: App.Data.CompanyData | null;
status: string;
receiver_phone: string;
duration: number | null;
receiver_name: string | null;
receiver_position: string | null;
next_action: string | null;
next_call_date: string | null;
appointment_flag: boolean;
notes: string | null;
called_at: string;
};
export type ClientData = {
id: number | null;
name: string;
contact_name: string | null;
contact_email: string | null;
contact_phone: string | null;
contract_start_date: string | null;
notes: string | null;
};
export type CompanyData = {
id: number | null;
corporate_number: string | null;
name: string;
name_kana: string | null;
phone_number: string;
industry: string | null;
zip_code: string | null;
address: string | null;
employee_count: number | null;
revenue: string | null;
listing_status: string | null;
url: string | null;
source: string;
};
export type ProjectData = {
id: number | null;
name: string;
client_id: number;
client: App.Data.ClientData | null;
status: string;
contract_type: string;
price_per_call: string | null;
price_per_appointment: string | null;
target_appointment_count: number | null;
start_date: string;
scheduled_end_date: string | null;
end_date: string | null;
notes: string | null;
total_calls: number | null;
total_appointments: number | null;
appointment_rate: number | null;
};
export type UserData = {
id: number;
name: string;
email: string;
};
}
declare namespace App.Data.Auth {
export type LoginData = {
email: string;
password: string;
remember: boolean;
};
}
declare namespace App.Enums {
export type CallResult = '01' | '02' | '03' | '04' | '05' | '06' | '07' | '08' | '09' | '99';
export type ContractType = 'per_call' | 'per_appointment' | 'hourly' | 'monthly_fixed';
export type ProjectStatus = 'preparing' | 'in_progress' | 'completed' | 'cancelled';
}
