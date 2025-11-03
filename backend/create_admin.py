#!/usr/bin/env python3
"""
Script to create an admin user for QuickSlot
"""
import sys
import asyncio
from app.database import AsyncSessionLocal
from app.models.user import User
from app.auth.utils import get_password_hash
from datetime import datetime
from sqlalchemy import select


async def create_admin_user(email: str, password: str, name: str = "Admin"):
    async with AsyncSessionLocal() as db:
        try:
            # Check if user already exists
            result = await db.execute(select(User).where(User.email == email))
            existing_user = result.scalar_one_or_none()
            
            if existing_user:
                print(f"❌ User with email {email} already exists!")
                if existing_user.is_admin:
                    print(f"✓ User is already an admin")
                else:
                    # Promote to admin
                    existing_user.is_admin = True
                    await db.commit()
                    print(f"✓ User promoted to admin")
                return
            
            # Create new admin user
            admin_user = User(
                email=email,
                hashed_password=get_password_hash(password),
                name=name,
                is_active=True,
                is_admin=True,
                created_at=datetime.utcnow(),
            )
            
            db.add(admin_user)
            await db.commit()
            await db.refresh(admin_user)
            
            print(f"✅ Admin user created successfully!")
            print(f"📧 Email: {admin_user.email}")
            print(f"👤 Name: {admin_user.name}")
            print(f"🆔 ID: {admin_user.id}")
            print(f"\n🔐 Use these credentials to login:")
            print(f"   Email: {email}")
            print(f"   Password: {password}")
            
        except Exception as e:
            print(f"❌ Error creating admin user: {e}")
            await db.rollback()


if __name__ == "__main__":
    print("=" * 60)
    print("QuickSlot - Create Admin User")
    print("=" * 60)
    
    # Default admin credentials
    email = input("Admin email (default: admin@quickslot.com): ").strip() or "admin@quickslot.com"
    password = input("Admin password (default: admin123): ").strip() or "admin123"
    name = input("Admin name (default: Admin): ").strip() or "Admin"
    
    print(f"\nCreating admin user...")
    asyncio.run(create_admin_user(email, password, name))
