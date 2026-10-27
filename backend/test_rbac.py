import urllib.request
import json

base_url = "http://127.0.0.1:8000/api/v1"

def test_endpoints():
    endpoints = ["/health", "/organizations", "/groups", "/roles", "/permissions", "/users", "/user/profile?user_id=usr_super"]
    for ep in endpoints:
        req = urllib.request.Request(base_url + ep)
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode())
            print(f"SUCCESS {ep}: {type(data)} with {len(data) if isinstance(data, (list, dict)) else data}")

    # Test Super Admin protection on register
    reg_req = urllib.request.Request(
        base_url + "/auth/register",
        data=json.dumps({"first_name": "Bad", "last_name": "Actor", "phone": "9999900000", "password": "password123", "role": "superAdmin"}).encode(),
        headers={"Content-Type": "application/json"}
    )
    try:
        urllib.request.urlopen(reg_req)
        print("FAIL: Super Admin registration was not blocked!")
    except urllib.error.HTTPError as e:
        print(f"SUCCESS: Super Admin registration blocked with status {e.code}")

    # Test Inactive user login blocked
    # 1. Create a user
    admin_usr_req = urllib.request.Request(
        base_url + "/users",
        data=json.dumps({
            "first_name": "Inactive",
            "last_name": "User",
            "phone": "9111122222",
            "role": "collector",
            "organization_id": "org_001",
            "is_active": False
        }).encode(),
        headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(admin_usr_req) as resp:
        created = json.loads(resp.read().decode())
        print(f"SUCCESS created inactive user: {created['id']}")

    # 2. Try login with inactive user
    login_req = urllib.request.Request(
        base_url + "/auth/login",
        data=json.dumps({"phone": "9111122222", "password": "vargani@123", "login_type": "password"}).encode(),
        headers={"Content-Type": "application/json"}
    )
    try:
        urllib.request.urlopen(login_req)
        print("FAIL: Inactive user login was not blocked!")
    except urllib.error.HTTPError as e:
        print(f"SUCCESS: Inactive user login correctly blocked with status {e.code}")

    # 3. Test select-group authorization
    sel_req = urllib.request.Request(
        base_url + "/auth/select-group",
        data=json.dumps({"user_id": "usr_collector2", "group_id": "grp_002"}).encode(),
        headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(sel_req) as resp:
        res = json.loads(resp.read().decode())
        print(f"SUCCESS authorized group selection: {res['group']['name']}")

    # 4. Test unauthorized group selection (usr_collector2 is only in grp_002, trying grp_003)
    unauth_sel_req = urllib.request.Request(
        base_url + "/auth/select-group",
        data=json.dumps({"user_id": "usr_collector2", "group_id": "grp_003"}).encode(),
        headers={"Content-Type": "application/json"}
    )
    try:
        urllib.request.urlopen(unauth_sel_req)
        print("FAIL: Unauthorized group selection was not blocked!")
    except urllib.error.HTTPError as e:
        print(f"SUCCESS: Unauthorized group selection blocked with status {e.code}")

if __name__ == "__main__":
    test_endpoints()
