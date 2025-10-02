const API_URL = 'http://localhost:8080/users';
const userForm = document.getElementById('userForm');
const usersTable = document.getElementById('usersTable').querySelector('tbody');
const addBtn = document.getElementById('addBtn');
const updateBtn = document.getElementById('updateBtn');
const userIdInput = document.getElementById('userId');

function fetchUsers() {
    fetch(API_URL)
        .then(res => res.json())
        .then(users => {
            usersTable.innerHTML = '';
            users.forEach(user => {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>${user.name}</td>
                    <td>${user.lastName}</td>
                    <td>${user.age}</td>
                    <td>${user.address}</td>
                    <td>
                        <button class="btn btn-sm btn-info mr-2" onclick="editUser('${user.id}')">Edit</button>
                        <button class="btn btn-sm btn-danger" onclick="deleteUser('${user.id}')">Delete</button>
                    </td>
                `;
                usersTable.appendChild(row);
            });
        });
}

userForm.onsubmit = function(e) {
    e.preventDefault();
    const user = {
        name: document.getElementById('name').value,
        lastName: document.getElementById('lastName').value,
        age: document.getElementById('age').value,
        address: document.getElementById('address').value
    };
    if (userIdInput.value) {
        updateUser(userIdInput.value, user);
    } else {
        addUser(user);
    }
};

function addUser(user) {
    fetch(API_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(user)
    }).then(() => {
        userForm.reset();
        fetchUsers();
    });
}

function editUser(id) {
    fetch(API_URL)
        .then(res => res.json())
        .then(users => {
            const user = users.find(u => u.id === id);
            if (user) {
                document.getElementById('name').value = user.name;
                document.getElementById('lastName').value = user.lastName;
                document.getElementById('age').value = user.age;
                document.getElementById('address').value = user.address;
                userIdInput.value = user.id;
                addBtn.style.display = 'none';
                updateBtn.style.display = 'inline-block';
            }
        });
}

updateBtn.onclick = function() {
    const id = userIdInput.value;
    const user = {
        name: document.getElementById('name').value,
        lastName: document.getElementById('lastName').value,
        age: document.getElementById('age').value,
        address: document.getElementById('address').value
    };
    updateUser(id, user);
};

function updateUser(id, user) {
    fetch(`${API_URL}/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(user)
    }).then(() => {
        userForm.reset();
        userIdInput.value = '';
        addBtn.style.display = 'inline-block';
        updateBtn.style.display = 'none';
        fetchUsers();
    });
}

function deleteUser(id) {
    if (confirm('Delete this user?')) {
        fetch(`${API_URL}/${id}`, {
            method: 'DELETE'
        }).then(() => fetchUsers());
    }
}

fetchUsers();
