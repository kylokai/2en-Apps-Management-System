<script setup>
import { ref, computed, watch } from 'vue';
import api from '../../services/api';

const props = defineProps({
  currentUser: Object,
  staffList: Array,
  initialMode: { type: String, default: 'profile' },
});
const emit = defineEmits(['refreshStaff', 'notify']);

const mode = ref(props.initialMode);
const selectedId = ref(props.currentUser?.employee?.id || 4);
const detail = ref(null);
const activeTab = ref('Overview');
const editMode = ref(false);
const showAddForm = ref(false);
const editForm = ref({});
const newEmp = ref({ full_name: '', email: '', position_title: '', department_name: '' });

const roleCode = computed(() => props.currentUser?.role_code || 'STAFF');
const isHR = computed(() => roleCode.value === 'HR_ADMIN');
const isBoss = computed(() => roleCode.value === 'OWNER_BOSS');
const isManager = computed(() => roleCode.value === 'MANAGER');
const isOwn = computed(() => Number(selectedId.value) === Number(props.currentUser?.employee?.id));
const isRestrictedViewer = computed(() => (isBoss.value || isManager.value) && !isOwn.value);

const visibleDirectory = computed(() => {
  const myId = props.currentUser?.employee?.id;
  const myName = props.currentUser?.employee?.full_name;
  return (props.staffList || []).filter((s) => {
    if (s.id === myId) return false;
    if (isManager.value) return s.manager_name === myName;
    return true;
  });
});

const visibleTabs = computed(() => {
  const all = ['Overview', 'Personal', 'Employment', 'Family & Emergency', 'Statutory & Payroll', 'Documents', 'Activity'];
  return isRestrictedViewer.value ? all.filter((t) => t !== 'Family & Emergency') : all;
});

async function loadProfile(id) {
  selectedId.value = id;
  activeTab.value = 'Overview';
  editMode.value = false;
  const res = await api.get(`/staff/${id}`);
  detail.value = res.data.data;
  const p = detail.value.profile;
  editForm.value = {
    phone: p.phone || '',
    email: p.email || '',
    address_1: p.address_1 || '',
    city: p.city || '',
    postcode: p.postcode || '',
    emergency_contact_name: p.emergency_contact_name || '',
    emergency_contact_phone: p.emergency_contact_phone || '',
  };
}

function openColleague(id) {
  mode.value = 'profile';
  loadProfile(id);
}

function openMyProfile() {
  mode.value = 'profile';
  loadProfile(props.currentUser?.employee?.id || 4);
}

async function saveProfile() {
  await api.patch(`/staff/${selectedId.value}`, editForm.value);
  editMode.value = false;
  await loadProfile(selectedId.value);
  emit('refreshStaff');
  emit('notify', 'Perubahan profil disimpan dan direkodkan dalam audit log.');
}

async function createEmployee() {
  if (!newEmp.value.full_name || !newEmp.value.email || !newEmp.value.position_title || !newEmp.value.department_name) {
    emit('notify', 'Sila lengkapkan semua medan pekerja baharu.');
    return;
  }
  const res = await api.post('/staff', newEmp.value);
  newEmp.value = { full_name: '', email: '', position_title: '', department_name: '' };
  showAddForm.value = false;
  emit('refreshStaff');
  emit('notify', res.data.message);
}

watch(() => props.initialMode, (val) => {
  mode.value = val;
  if (val === 'profile') openMyProfile();
}, { immediate: true });
</script>

<template>
  <!-- MOD 1: DIREKTORI STAF / PASUKAN (HR, BOSS, MANAGER) -->
  <div v-if="mode === 'directory'">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px">
      <div>
        <h2 style="margin:0">{{ isManager ? 'Team Directory' : 'Staff Directory' }}</h2>
        <p style="margin:2px 0 0;color:var(--silver-500);font-size:13px">Klik baris pekerja untuk membuka halaman Staff Profile berasingan.</p>
      </div>
      <button v-if="isHR" class="btn btn-primary" @click="showAddForm = !showAddForm">
        {{ showAddForm ? 'Tutup Borang' : '+ Add Employee' }}
      </button>
    </div>

    <div v-if="showAddForm && isHR" class="card" style="margin-bottom:16px">
      <h3 style="margin-top:0">Tambah Pekerja Baharu (Simpan ke MySQL)</h3>
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px">
        <input class="input" v-model="newEmp.full_name" placeholder="Nama Penuh (cth: Nur Aisyah Binti Ahmad)" />
        <input class="input" v-model="newEmp.email" placeholder="Emel Kerja (cth: aisyah@2enapps.my)" />
        <input class="input" v-model="newEmp.position_title" placeholder="Jawatan (cth: Software Engineer)" />
        <input class="input" v-model="newEmp.department_name" placeholder="Jabatan (cth: Information Technology)" />
      </div>
      <div style="margin-top:12px">
        <button class="btn btn-primary" @click="createEmployee">Simpan Pekerja</button>
      </div>
    </div>

    <div class="card">
      <table class="data">
        <thead>
          <tr>
            <th>Employee</th>
            <th>ID</th>
            <th>Position</th>
            <th>Department</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="s in visibleDirectory" :key="s.id" class="clickable" @click="openColleague(s.id)">
            <td>
              <b>{{ s.full_name }}</b><br />
              <small style="color:var(--silver-500)">{{ s.email }}</small>
            </td>
            <td><code>{{ s.employee_no }}</code></td>
            <td>{{ s.position_title || 'Not applicable' }}</td>
            <td>{{ s.department_name || 'Owner entity' }}</td>
            <td><span class="pill green">{{ s.employment_status }}</span></td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>

  <!-- MOD 2: STAFF PROFILE (7 TAB ZIYAD) -->
  <div v-else-if="detail">
    <div v-if="!isOwn && (isHR || isBoss || isManager)" style="margin-bottom:12px">
      <button class="btn btn-sm" @click="mode = 'directory'">← Back to {{ isManager ? 'Team' : 'Staff' }} Directory</button>
    </div>

    <!-- Profile Hero -->
    <div class="card" style="padding:0;overflow:hidden;margin-bottom:16px">
      <div style="height:88px;background:linear-gradient(110deg,#12265E,#1E4BB8 65%,#3B73E8)"></div>
      <div style="padding:16px 22px;display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:12px">
        <div>
          <h2 style="margin:0;display:flex;align-items:center;gap:8px">
            {{ detail.profile.full_name }}
            <span class="pill blue">{{ detail.role?.name || 'Staff' }}</span>
          </h2>
          <div style="color:var(--silver-500);font-size:13px;margin-top:4px">
            {{ detail.profile.employee_no }}
            <span v-if="detail.directory?.position_title"> • {{ detail.directory.position_title }}</span>
            <span v-if="detail.directory?.department_name"> • {{ detail.directory.department_name }}</span>
            <span v-if="detail.directory?.branch_name"> • {{ detail.directory.branch_name }}</span>
          </div>
        </div>
        <div style="display:flex;gap:8px">
          <button v-if="isHR || isOwn" class="btn" @click="editMode = !editMode">
            {{ editMode ? 'Batal Edit' : (isOwn ? 'Request / Edit Contact' : 'Edit Profile') }}
          </button>
          <button v-if="editMode" class="btn btn-primary" @click="saveProfile">Simpan Perubahan</button>
          <button v-if="!isOwn" class="btn" @click="openMyProfile">My Staff Profile</button>
        </div>
      </div>
    </div>

    <!-- 7 Tabs -->
    <div class="card">
      <div style="display:flex;gap:6px;border-bottom:1px solid var(--silver-200);margin-bottom:18px;overflow-x:auto">
        <button
          v-for="tab in visibleTabs"
          :key="tab"
          @click="activeTab = tab"
          style="background:none;border:none;padding:10px 14px;font-weight:700;font-size:13px"
          :style="{
            color: activeTab === tab ? 'var(--royal-700)' : 'var(--silver-500)',
            borderBottom: activeTab === tab ? '2px solid var(--royal-600)' : '2px solid transparent'
          }"
        >
          {{ tab }}
        </button>
      </div>

      <!-- Tab 1: Overview -->
      <div v-if="activeTab === 'Overview'" style="display:grid;grid-template-columns:1fr 1fr;gap:16px">
        <div><small style="color:var(--silver-400)">FULL NAME</small><br /><b>{{ detail.profile.full_name }}</b></div>
        <div><small style="color:var(--silver-400)">{{ detail.profile.employee_no === 'OWNER-0001' ? 'OWNER ID' : 'STAFF ID' }}</small><br /><b>{{ detail.profile.employee_no }}</b></div>
        <div v-if="detail.directory?.position_title"><small style="color:var(--silver-400)">POSITION</small><br /><b>{{ detail.directory.position_title }}</b></div>
        <div v-if="detail.directory?.department_name"><small style="color:var(--silver-400)">DEPARTMENT</small><br /><b>{{ detail.directory.department_name }}</b></div>
        <div><small style="color:var(--silver-400)">DATE JOINED</small><br /><b>{{ detail.profile.hire_date || '—' }}</b></div>
        <div><small style="color:var(--silver-400)">WORK EMAIL</small><br /><b>{{ detail.profile.email }}</b></div>
      </div>

      <!-- Tab 2: Personal -->
      <div v-else-if="activeTab === 'Personal'" style="display:grid;grid-template-columns:1fr 1fr;gap:16px">
        <div><small style="color:var(--silver-400)">FULL NAME</small><br /><b>{{ detail.profile.full_name }}</b></div>
        <div><small style="color:var(--silver-400)">DATE OF BIRTH</small><br /><b>{{ detail.profile.date_of_birth || '—' }}</b></div>
        <div><small style="color:var(--silver-400)">NATIONALITY</small><br /><b>{{ detail.profile.nationality_code }}</b></div>
        <div><small style="color:var(--silver-400)">MARITAL STATUS</small><br /><b>{{ detail.profile.marital_status || '—' }}</b></div>
        <div>
          <small style="color:var(--silver-400)">MOBILE NUMBER</small><br />
          <input v-if="editMode" class="input" v-model="editForm.phone" />
          <b v-else>{{ detail.profile.phone || '—' }}</b>
        </div>
        <div>
          <small style="color:var(--silver-400)">WORK EMAIL</small><br />
          <input v-if="editMode" class="input" v-model="editForm.email" />
          <b v-else>{{ detail.profile.email }}</b>
        </div>
        <div style="grid-column:1/-1">
          <small style="color:var(--silver-400)">HOME ADDRESS</small><br />
          <input v-if="editMode" class="input" v-model="editForm.address_1" />
          <b v-else>{{ detail.profile.address_1 || '—' }}, {{ detail.profile.postcode }} {{ detail.profile.city }}</b>
        </div>
      </div>

      <!-- Tab 3: Employment -->
      <div v-else-if="activeTab === 'Employment'" style="display:grid;grid-template-columns:1fr 1fr;gap:16px">
        <div><small style="color:var(--silver-400)">EMPLOYMENT TYPE</small><br /><b>{{ detail.profile.employment_type }}</b></div>
        <div><small style="color:var(--silver-400)">STATUS</small><br /><span class="pill green">{{ detail.profile.employment_status }}</span></div>
        <div v-if="detail.directory?.manager_name"><small style="color:var(--silver-400)">REPORTING MANAGER</small><br /><b>{{ detail.directory.manager_name }}</b></div>
        <div><small style="color:var(--silver-400)">CONFIRMATION DATE</small><br /><b>{{ detail.profile.confirmation_date || '—' }}</b></div>
      </div>

      <!-- Tab 4: Family & Emergency -->
      <div v-else-if="activeTab === 'Family & Emergency'" style="display:grid;grid-template-columns:1fr 1fr;gap:16px">
        <div><small style="color:var(--silver-400)">NEXT OF KIN</small><br /><b>{{ detail.profile.next_of_kin_name || '—' }}</b></div>
        <div><small style="color:var(--silver-400)">NEXT OF KIN PHONE</small><br /><b>{{ detail.profile.next_of_kin_phone || '—' }}</b></div>
        <div>
          <small style="color:var(--silver-400)">EMERGENCY CONTACT</small><br />
          <input v-if="editMode" class="input" v-model="editForm.emergency_contact_name" />
          <b v-else>{{ detail.profile.emergency_contact_name || '—' }}</b>
        </div>
        <div>
          <small style="color:var(--silver-400)">EMERGENCY PHONE</small><br />
          <input v-if="editMode" class="input" v-model="editForm.emergency_contact_phone" />
          <b v-else>{{ detail.profile.emergency_contact_phone || '—' }}</b>
        </div>
      </div>

      <!-- Tab 5: Statutory & Payroll (Masked untuk bukan HR Admin) -->
      <div v-else-if="activeTab === 'Statutory & Payroll'">
        <div v-if="!isHR" style="background:var(--royal-50);border:1px solid #D9E6FF;padding:10px 14px;border-radius:10px;margin-bottom:14px;font-size:12px;color:var(--royal-700)">
          🔒 Seksyen Terhad (PDPA): Nombor EPF, SOCSO, LHDN dan gaji hanya dipaparkan penuh kepada HR Admin.
        </div>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:16px">
          <div><small style="color:var(--silver-400)">EPF (KWSP)</small><br /><b :class="{ 'locked-val': !isHR }">{{ detail.profile.epf_member_no || '••••••••' }}</b></div>
          <div><small style="color:var(--silver-400)">SOCSO (PERKESO)</small><br /><b :class="{ 'locked-val': !isHR }">{{ detail.profile.socso_member_no || '••••••••' }}</b></div>
          <div><small style="color:var(--silver-400)">LHDN INCOME TAX</small><br /><b :class="{ 'locked-val': !isHR }">{{ detail.profile.lhdn_tax_no || '••••••••' }}</b></div>
          <div><small style="color:var(--silver-400)">BASIC SALARY (RM)</small><br /><b :class="{ 'locked-val': !isHR }">{{ detail.profile.basic_salary ? 'RM ' + detail.profile.basic_salary : '—' }}</b></div>
        </div>
      </div>

      <!-- Tab 6: Documents -->
      <div v-else-if="activeTab === 'Documents'">
        <p v-if="!detail.documents || detail.documents.length === 0" style="color:var(--silver-500)">Tiada dokumen dimuat naik dalam pangkalan data lagi.</p>
        <ul v-else>
          <li v-for="doc in detail.documents" :key="doc.id">{{ doc.title }} ({{ doc.document_type }})</li>
        </ul>
      </div>

      <!-- Tab 7: Activity (Audit Log sebenar dari MySQL) -->
      <div v-else-if="activeTab === 'Activity'">
        <p v-if="!detail.audits || detail.audits.length === 0" style="color:var(--silver-500)">Belum ada rekod audit log bagi profil ini.</p>
        <div v-for="a in detail.audits" :key="a.id" style="padding:8px 0;border-bottom:1px solid var(--silver-100);font-size:13px">
          <b>{{ a.action }}</b> pada jadual <code>{{ a.table_name }}</code> — <small style="color:var(--silver-400)">{{ a.created_at }}</small>
        </div>
      </div>
    </div>
  </div>
</template>