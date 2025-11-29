# Keystore Setup Instructions

## ⚠️ IMPORTANT: Read This First

**You need a signing keystore to build a production AAB for Google Play.**

- The keystore is used to sign your app
- **If you lose the keystore, you CANNOT update your app on Google Play**
- **Never commit the keystore to git**
- **Backup the keystore file and passwords securely**

---

## 🚀 Quick Setup (Automated)

Run the setup script:

```bash
cd /Users/ahmad/Desktop/Awsaltak/driver-app
./setup-keystore.sh
```

The script will:
1. Create a keystore file in your home directory (`~/wassle-driver-keystore.jks`)
2. Prompt you for passwords
3. Create `android/key.properties` file
4. Update `.gitignore` to exclude keystore files

---

## 📝 Manual Setup

If you prefer to set up manually:

### Step 1: Create Keystore

```bash
cd /Users/ahmad/Desktop/Awsaltak/driver-app/android

keytool -genkey -v -keystore ~/wassle-driver-keystore.jks \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -alias wassle-driver
```

**You will be prompted for:**
- Keystore password (remember this!)
- Key password (usually same as keystore password)
- Your name, organization, city, state, country code

### Step 2: Create key.properties

```bash
cd /Users/ahmad/Desktop/Awsaltak/driver-app/android

cat > key.properties << EOF
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=wassle-driver
storeFile=/Users/ahmad/wassle-driver-keystore.jks
EOF
```

**Replace:**
- `YOUR_KEYSTORE_PASSWORD` with your keystore password
- `YOUR_KEY_PASSWORD` with your key password
- Update the `storeFile` path if you saved keystore in a different location

### Step 3: Verify .gitignore

Make sure these lines are in `.gitignore`:
```
android/key.properties
*.jks
*.keystore
```

---

## ✅ Verify Setup

After setup, verify the files exist:

```bash
# Check keystore exists
ls -lh ~/wassle-driver-keystore.jks

# Check key.properties exists
ls -lh android/key.properties

# Verify key.properties content (will show passwords - be careful!)
cat android/key.properties
```

---

## 🔒 Security Best Practices

1. **Backup the keystore:**
   ```bash
   cp ~/wassle-driver-keystore.jks ~/backups/
   ```

2. **Store passwords securely:**
   - Use a password manager
   - Don't store in plain text files
   - Don't commit to git

3. **Keep keystore safe:**
   - Store in secure location
   - Multiple backups (encrypted)
   - Never share publicly

---

## 🚀 After Setup

Once keystore is set up, you can build the AAB:

```bash
./build-aab.sh
```

The build will now use your production signing key instead of debug signing.

---

## ❓ Troubleshooting

### "keytool: command not found"
- Install Java JDK
- On macOS: `brew install openjdk`
- Verify: `keytool -version`

### "Keystore was tampered with, or password was incorrect"
- Check your passwords
- Make sure `key.properties` has correct passwords

### "Cannot find keystore file"
- Check the path in `key.properties`
- Use absolute path: `/Users/ahmad/wassle-driver-keystore.jks`
- Or relative path from project root

---

## 📋 Checklist

- [ ] Keystore created (`~/wassle-driver-keystore.jks`)
- [ ] `android/key.properties` created
- [ ] Passwords saved securely
- [ ] Keystore backed up
- [ ] `.gitignore` updated
- [ ] Verified setup works

---

**Next Step:** Run `./build-aab.sh` to build your production AAB!

