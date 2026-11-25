<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Syarikat & Cawangan
        DB::table('companies')->updateOrInsert(
            ['id' => 1],
            [
                'name' => '2en Apps Sdn. Bhd.',
                'registration_no' => '201901000001',
                'address' => 'Cyberjaya, Selangor',
                'state_code' => 'SELANGOR',
                'country' => 'MALAYSIA',
                'region_rule_set' => 'EMACT_1955',
                'is_active' => true,
            ]
        );

        DB::table('branches')->updateOrInsert(
            ['id' => 1],
            ['company_id' => 1, 'name' => 'Cyberjaya', 'code' => 'CYB', 'state_code' => 'SELANGOR', 'is_active' => true]
        );
        DB::table('branches')->updateOrInsert(
            ['id' => 2],
            ['company_id' => 1, 'name' => 'Ampang', 'code' => 'AMP', 'state_code' => 'SELANGOR', 'is_active' => true]
        );

        // 2. Jabatan & Jawatan
        DB::table('departments')->updateOrInsert(
            ['id' => 1],
            ['company_id' => 1, 'branch_id' => 1, 'name' => 'Information Technology', 'code' => 'IT', 'is_active' => true]
        );
        DB::table('departments')->updateOrInsert(
            ['id' => 2],
            ['company_id' => 1, 'branch_id' => 2, 'name' => 'Human Resource', 'code' => 'HR', 'is_active' => true]
        );

        DB::table('positions')->updateOrInsert(
            ['id' => 1],
            ['company_id' => 1, 'department_id' => 1, 'title' => 'IT Team Lead', 'code' => 'IT-M1', 'job_grade' => 'M1', 'is_active' => true]
        );
        DB::table('positions')->updateOrInsert(
            ['id' => 2],
            ['company_id' => 1, 'department_id' => 1, 'title' => 'Software Engineer', 'code' => 'IT-E3', 'job_grade' => 'E3', 'is_active' => true]
        );
        DB::table('positions')->updateOrInsert(
            ['id' => 3],
            ['company_id' => 1, 'department_id' => 1, 'title' => 'Intern Developer', 'code' => 'IT-INT', 'job_grade' => 'INT', 'is_active' => true]
        );
        DB::table('positions')->updateOrInsert(
            ['id' => 4],
            ['company_id' => 1, 'department_id' => 2, 'title' => 'HR Manager', 'code' => 'HR-M2', 'job_grade' => 'M2', 'is_active' => true]
        );

        // 3. Akaun Log Masuk (kata laluan: demo1234)
        $password = Hash::make('demo1234');$accounts = [
            ['id' => 1, 'username' => 'faisal', 'email' => 'faisal@2enapps.my', 'role_code' => 'OWNER_BOSS'],
            ['id' => 2, 'username' => 'siti', 'email' => 'aminah.osman@2enapps.my', 'role_code' => 'HR_ADMIN'],
            ['id' => 3, 'username' => 'manager', 'email' => 'wei.jian@2enapps.my', 'role_code' => 'MANAGER'],
            ['id' => 4, 'username' => 'aina', 'email' => 'aina.rahman@2enapps.my', 'role_code' => 'STAFF'],
            ['id' => 5, 'username' => 'arif', 'email' => 'arif.kamal@2enapps.my', 'role_code' => 'INTERN'],
        ];

        foreach ($accounts as$acc) {
            DB::table('user_accounts')->updateOrInsert(
                ['id' => $acc['id']],
                ['username' => $acc['username'], 'email' => $acc['email'], 'password_hash' =>$password, 'status' => 'Active']
            );
            $roleId = DB::table('roles')->where('code',$acc['role_code'])->value('id');
            if ($roleId) {
                DB::table('user_roles')->updateOrInsert(['user_id' => $acc['id'], 'role_id' =>$roleId], []);
            }
        }

        // 4. Rekod Pekerja (5 orang mengikut prototaip Ziyad)
        $employees = [
            [
                'id' => 1, 'employee_no' => 'OWNER-0001', 'company_id' => 1, 'branch_id' => 1, 'department_id' => null, 'position_id' => null,
                'reports_to_employee_id' => null, 'user_id' => 1, 'first_name' => 'Mohd Faisal', 'last_name' => 'Bin Kamal',
                'full_name' => 'Mohd Faisal Bin Kamal', 'date_of_birth' => '1985-11-03', 'gender_code' => 'M', 'race_code' => 'MALAY',
                'religion_code' => 'ISLAM', 'nationality_code' => 'MALAYSIAN', 'marital_status' => 'MARRIED',
                'address_1' => 'No. 21, Jalan Putra', 'city' => 'Ampang', 'postcode' => '68000', 'state_code' => 'SELANGOR',
                'phone' => '019-333 2211', 'email' => 'faisal@2enapps.my',
                'emergency_contact_name' => 'Siti Aisyah Bt Yusof', 'emergency_contact_relationship' => 'SPOUSE', 'emergency_contact_phone' => '013-444 8899',
                'next_of_kin_name' => 'Siti Aisyah Bt Yusof', 'next_of_kin_relationship' => 'SPOUSE', 'next_of_kin_phone' => '013-444 8899',
                'employment_type' => 'DIRECTOR', 'employment_status' => 'Active', 'hire_date' => '2019-01-01',
                'basic_salary' => null, 'epf_member_no' => null, 'socso_member_no' => null, 'lhdn_tax_no' => null,
            ],
            [
                'id' => 2, 'employee_no' => 'EMP-2021-0007', 'company_id' => 1, 'branch_id' => 2, 'department_id' => 2, 'position_id' => 4,
                'reports_to_employee_id' => null, 'user_id' => 2, 'first_name' => 'Siti Aminah', 'last_name' => 'Binti Osman',
                'full_name' => 'Siti Aminah Binti Osman', 'date_of_birth' => '1988-04-25', 'gender_code' => 'F', 'race_code' => 'MALAY',
                'religion_code' => 'ISLAM', 'nationality_code' => 'MALAYSIAN', 'marital_status' => 'MARRIED',
                'address_1' => 'No. 3, Jalan Ukay', 'city' => 'Ampang', 'postcode' => '68000', 'state_code' => 'SELANGOR',
                'phone' => '012-888 2200', 'email' => 'aminah.osman@2enapps.my',
                'emergency_contact_name' => 'Osman Bin Ahmad', 'emergency_contact_relationship' => 'PARENT', 'emergency_contact_phone' => '017-555 1234',
                'next_of_kin_name' => 'Osman Bin Ahmad', 'next_of_kin_relationship' => 'PARENT', 'next_of_kin_phone' => '017-555 1234',
                'employment_type' => 'PERMANENT', 'employment_status' => 'Active', 'hire_date' => '2021-06-01', 'confirmation_date' => '2021-12-01',
                'basic_salary' => 11800.00, 'epf_member_no' => 'D11229901', 'socso_member_no' => '880425127788', 'lhdn_tax_no' => 'SG112299010',
            ],
            [
                'id' => 3, 'employee_no' => 'EMP-2024-0025', 'company_id' => 1, 'branch_id' => 1, 'department_id' => 1, 'position_id' => 1,
                'reports_to_employee_id' => 1, 'user_id' => 3, 'first_name' => 'Wei Jian', 'last_name' => 'Lim',
                'full_name' => 'Lim Wei Jian', 'date_of_birth' => '1992-05-09', 'gender_code' => 'M', 'race_code' => 'CHINESE',
                'religion_code' => 'BUDDHISM', 'nationality_code' => 'MALAYSIAN', 'marital_status' => 'MARRIED',
                'address_1' => 'No. 18, Jalan Cyber 8, Cyber 12', 'city' => 'Cyberjaya', 'postcode' => '63000', 'state_code' => 'SELANGOR',
                'phone' => '016-720 4410', 'email' => 'wei.jian@2enapps.my',
                'emergency_contact_name' => 'Tan Mei Ling', 'emergency_contact_relationship' => 'SPOUSE', 'emergency_contact_phone' => '017-330 8890',
                'next_of_kin_name' => 'Tan Mei Ling', 'next_of_kin_relationship' => 'SPOUSE', 'next_of_kin_phone' => '017-330 8890',
                'employment_type' => 'PERMANENT', 'employment_status' => 'Active', 'hire_date' => '2024-07-10', 'confirmation_date' => '2025-01-10',
                'basic_salary' => 10400.00, 'epf_member_no' => 'C55667788', 'socso_member_no' => '920509083344', 'lhdn_tax_no' => 'SG556677880',
            ],
            [
                'id' => 4, 'employee_no' => 'EMP-2026-0042', 'company_id' => 1, 'branch_id' => 1, 'department_id' => 1, 'position_id' => 2,
                'reports_to_employee_id' => 3, 'user_id' => 4, 'first_name' => 'Aina', 'last_name' => 'Binti Rahman',
                'full_name' => 'Aina Binti Rahman', 'date_of_birth' => '1996-07-14', 'gender_code' => 'F', 'race_code' => 'MALAY',
                'religion_code' => 'ISLAM', 'nationality_code' => 'MALAYSIAN', 'marital_status' => 'SINGLE',
                'address_1' => 'No. 12, Jalan Cyber 5, Cyber 12', 'city' => 'Cyberjaya', 'postcode' => '63000', 'state_code' => 'SELANGOR',
                'phone' => '012-345 6789', 'email' => 'aina.rahman@2enapps.my',
                'emergency_contact_name' => 'Rahman Bin Ali', 'emergency_contact_relationship' => 'PARENT', 'emergency_contact_phone' => '019-876 5432',
                'next_of_kin_name' => 'Rahman Bin Ali', 'next_of_kin_relationship' => 'PARENT', 'next_of_kin_phone' => '019-876 5432',
                'employment_type' => 'PERMANENT', 'employment_status' => 'Active', 'hire_date' => '2023-03-01', 'confirmation_date' => '2023-09-01',
                'basic_salary' => 7500.00, 'epf_member_no' => 'A12345678', 'socso_member_no' => '940714125678', 'lhdn_tax_no' => 'SG123456780',
            ],
            [
                'id' => 5, 'employee_no' => 'EMP-2026-0071', 'company_id' => 1, 'branch_id' => 1, 'department_id' => 1, 'position_id' => 3,
                'reports_to_employee_id' => 3, 'user_id' => 5, 'first_name' => 'Muhammad Arif', 'last_name' => 'Bin Kamal',
                'full_name' => 'Muhammad Arif Bin Kamal', 'date_of_birth' => '2001-02-20', 'gender_code' => 'M', 'race_code' => 'MALAY',
                'religion_code' => 'ISLAM', 'nationality_code' => 'MALAYSIAN', 'marital_status' => 'SINGLE',
                'address_1' => 'No. 8, Jalan UP 1/2, Ukay Perdana', 'city' => 'Ampang', 'postcode' => '68000', 'state_code' => 'SELANGOR',
                'phone' => '017-222 1188', 'email' => 'arif.kamal@2enapps.my',
                'emergency_contact_name' => 'Kamal Bin Hussin', 'emergency_contact_relationship' => 'PARENT', 'emergency_contact_phone' => '012-998 1122',
                'next_of_kin_name' => 'Kamal Bin Hussin', 'next_of_kin_relationship' => 'PARENT', 'next_of_kin_phone' => '012-998 1122',
                'employment_type' => 'INTERN', 'employment_status' => 'Probation', 'hire_date' => '2026-09-15', 'confirmation_date' => '2026-12-15',
                'basic_salary' => 1800.00, 'epf_member_no' => 'B99887766', 'socso_member_no' => '010220141122', 'lhdn_tax_no' => null,
            ],
        ];

        foreach ($employees as$emp) {
            DB::table('employees')->updateOrInsert(['id' => $emp['id']],$emp);
        }
    }
}