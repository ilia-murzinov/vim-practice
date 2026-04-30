import React, { useState, useCallback } from 'react';
import type { User } from './types';

interface UserCardProps {
  user: User;
  onEdit?: (userId: string) => void;
  onDelete?: (userId: string) => void;
  showActions?: boolean;
  compact?: boolean;
}

function getStatusColor(status: User['status']): string {
  switch (status) {
    case 'ACTIVE':
      return 'text-green-600 bg-green-50';
    case 'SUSPENDED':
      return 'text-yellow-600 bg-yellow-50';
    case 'DELETED':
      return 'text-red-600 bg-red-50';
    default:
      return 'text-gray-600 bg-gray-50';
  }
}

function formatFullName(firstName: string, lastName: string): string {
  return `${firstName} ${lastName}`.trim();
}

export function UserCard({
  user,
  onEdit,
  onDelete,
  showActions = true,
  compact = false,
}: UserCardProps) {
  const [isDeleting, setIsDeleting] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);

  const fullName = formatFullName(user.firstName, user.lastName);
  const statusClass = getStatusColor(user.status);

  const handleDeleteClick = useCallback(() => {
    if (!confirmDelete) {
      setConfirmDelete(true);
      return;
    }
    setIsDeleting(true);
    onDelete?.(user.id);
  }, [confirmDelete, onDelete, user.id]);

  const handleCancelDelete = useCallback(() => {
    setConfirmDelete(false);
  }, []);

  if (compact) {
    return (
      <div className="flex items-center gap-3 p-3 rounded-lg border border-gray-200">
        <div className="w-8 h-8 rounded-full bg-blue-500 flex items-center justify-center text-white text-sm font-medium">
          {user.firstName[0]}{user.lastName[0]}
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-sm font-medium text-gray-900 truncate">{fullName}</p>
          <p className="text-xs text-gray-500 truncate">{user.email}</p>
        </div>
        <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${statusClass}`}>
          {user.status}
        </span>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
      <div className="p-6">
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-full bg-blue-500 flex items-center justify-center text-white text-lg font-semibold">
              {user.firstName[0]}{user.lastName[0]}
            </div>
            <div>
              <h3 className="text-lg font-semibold text-gray-900">{fullName}</h3>
              <p className="text-sm text-gray-500">{user.email}</p>
            </div>
          </div>
          <span className={`text-sm px-3 py-1 rounded-full font-medium ${statusClass}`}>
            {user.status}
          </span>
        </div>

        {user.address && (
          <div className="mt-4 text-sm text-gray-600">
            <p>{user.address.street}</p>
            <p>{user.address.city}, {user.address.state} {user.address.postalCode}</p>
            <p>{user.address.country}</p>
          </div>
        )}

        <div className="mt-4 text-xs text-gray-400">
          Joined {new Date(user.createdAt).toLocaleDateString()}
        </div>
      </div>

      {showActions && (
        <div className="px-6 py-4 bg-gray-50 border-t border-gray-200 flex items-center justify-between">
          <button
            onClick={() => onEdit?.(user.id)}
            className="text-sm text-blue-600 hover:text-blue-700 font-medium"
          >
            Edit
          </button>

          <div className="flex items-center gap-2">
            {confirmDelete && (
              <button
                onClick={handleCancelDelete}
                className="text-sm text-gray-500 hover:text-gray-700"
              >
                Cancel
              </button>
            )}
            <button
              onClick={handleDeleteClick}
              disabled={isDeleting}
              className="text-sm text-red-600 hover:text-red-700 font-medium disabled:opacity-50"
            >
              {confirmDelete ? 'Confirm delete' : 'Delete'}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
