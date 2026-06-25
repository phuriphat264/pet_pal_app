"""password reset tokens + case-insensitive emails

Revision ID: 5d42504544c1
Revises: bdeba019efb4
Create Date: 2026-06-25 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '5d42504544c1'
down_revision: Union[str, Sequence[str], None] = 'bdeba019efb4'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column('users', sa.Column('password_reset_token_hash', sa.String(length=64), nullable=True))
    op.add_column('users', sa.Column('password_reset_expires_at', sa.DateTime(timezone=True), nullable=True))
    # Emails are now treated as case-insensitive everywhere (registration,
    # login, OAuth); normalize existing rows so lookups by lowercased email
    # keep matching accounts created before this change.
    op.execute("UPDATE users SET email = lower(email)")


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_column('users', 'password_reset_expires_at')
    op.drop_column('users', 'password_reset_token_hash')
