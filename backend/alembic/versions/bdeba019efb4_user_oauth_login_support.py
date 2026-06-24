"""user oauth login support

Revision ID: bdeba019efb4
Revises: 48d668033df3
Create Date: 2026-06-24 14:17:38.269990

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'bdeba019efb4'
down_revision: Union[str, Sequence[str], None] = '48d668033df3'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Note: the ix_hotels_embedding_hnsw drop/recreate that autogenerate
    # detected here is a false positive -- that index is created via raw
    # SQL in the initial migration (not declared as SQLAlchemy metadata),
    # so it's intentionally omitted from this migration.
    op.add_column('users', sa.Column('oauth_provider', sa.String(length=32), nullable=True))
    op.alter_column('users', 'password_hash',
               existing_type=sa.VARCHAR(length=255),
               nullable=True)


def downgrade() -> None:
    """Downgrade schema."""
    op.alter_column('users', 'password_hash',
               existing_type=sa.VARCHAR(length=255),
               nullable=False)
    op.drop_column('users', 'oauth_provider')
