<?php
/**
 * StatusHelper - Helper functions for ITR Order Status Management
 */
class StatusHelper {
    
    /**
     * Get status step title by step code
     */
    public static function getStepTitle($step) {
        $titles = [
            'payment_success' => 'Payment Success',
            'expert_assigned' => 'Tax Expert Assigned',
            'documents_verified' => 'Documents Verification',
            'filing_itr' => 'Filing ITR',
            'acknowledgement_generated' => 'Acknowledgement Generated'
        ];
        return $titles[$step] ?? $step;
    }
    
    /**
     * Get step order number
     */
    public static function getStepOrder($step) {
        $orders = [
            'payment_success' => 1,
            'expert_assigned' => 2,
            'documents_verified' => 3,
            'filing_itr' => 4,
            'acknowledgement_generated' => 5
        ];
        return $orders[$step] ?? 0;
    }
    
    /**
     * Get all status steps in order
     */
    public static function getAllSteps() {
        return [
            'payment_success',
            'expert_assigned',
            'documents_verified',
            'filing_itr',
            'acknowledgement_generated'
        ];
    }
    
    /**
     * Create or update a status step
     */
    public static function updateStatusStep($conn, $orderId, $itrId, $userId, $paymentId, $panNumber, $statusStep, $isCompleted = false, $notes = null) {
        $userIdEscaped = mysqli_real_escape_string($conn, $userId);
        $statusStepEscaped = mysqli_real_escape_string($conn, $statusStep);
        $isCompletedInt = $isCompleted ? 1 : 0;
        
        // Prepare escaped values for WHERE clause
        $orderIdEscaped = $orderId ? mysqli_real_escape_string($conn, $orderId) : null;
        $itrIdEscaped = $itrId ? (int)$itrId : null;
        
        // Prepare escaped values for INSERT/UPDATE
        $orderIdValue = $orderId ? "'" . mysqli_real_escape_string($conn, $orderId) . "'" : 'NULL';
        $itrIdValue = $itrId ? (int)$itrId : 'NULL';
        $paymentIdEscaped = $paymentId ? "'" . mysqli_real_escape_string($conn, $paymentId) . "'" : 'NULL';
        $panNumberEscaped = $panNumber ? "'" . mysqli_real_escape_string($conn, $panNumber) . "'" : 'NULL';
        $notesEscaped = $notes ? "'" . mysqli_real_escape_string($conn, $notes) . "'" : 'NULL';
        
        // Check if status step already exists
        $whereClause = "user_id = '$userIdEscaped' AND status_step = '$statusStepEscaped'";
        if ($orderIdEscaped) {
            $whereClause .= " AND order_id = '$orderIdEscaped'";
        } else {
            $whereClause .= " AND order_id IS NULL";
        }
        if ($itrIdEscaped) {
            $whereClause .= " AND itr_id = $itrIdEscaped";
        } else {
            $whereClause .= " AND itr_id IS NULL";
        }
        
        $checkSql = "SELECT id, has_concern FROM itr_order_status WHERE $whereClause LIMIT 1";
        $checkResult = $conn->query($checkSql);
        
        if ($checkResult && $checkResult->num_rows > 0) {
            // Update existing record
            $existing = $checkResult->fetch_assoc();
            $hasConcern = $existing['has_concern'];
            
            // Don't mark as completed if there's a pending concern
            if ($hasConcern) {
                // Check if there are any pending concerns
                $concernCheckSql = "SELECT COUNT(*) as count FROM itr_order_concerns WHERE status_id = " . (int)$existing['id'] . " AND status = 'pending'";
                $concernResult = $conn->query($concernCheckSql);
                if ($concernResult) {
                    $concernData = $concernResult->fetch_assoc();
                    if ($concernData['count'] > 0) {
                        $isCompletedInt = 0; // Force incomplete if concern exists
                    }
                }
            }
            
            $updateFields = [
                "is_completed = $isCompletedInt",
                "updated_at = NOW()"
            ];
            
            if ($isCompletedInt && !$hasConcern) {
                $updateFields[] = "completed_at = NOW()";
            }
            
            if ($notes !== null) {
                $updateFields[] = "notes = $notesEscaped";
            }
            
            $updateSql = "UPDATE itr_order_status SET " . implode(", ", $updateFields) . " WHERE id = " . (int)$existing['id'];
            return $conn->query($updateSql);
        } else {
            // Insert new record
            $paymentIdValue = $paymentIdEscaped !== 'NULL' ? $paymentIdEscaped : 'NULL';
            $panNumberValue = $panNumberEscaped !== 'NULL' ? $panNumberEscaped : 'NULL';
            $completedAtValue = $isCompletedInt ? 'NOW()' : 'NULL';
            
            $insertSql = "INSERT INTO itr_order_status 
                (order_id, itr_id, user_id, payment_id, pan_number, status_step, is_completed, completed_at, notes, created_at, updated_at)
                VALUES 
                ($orderIdValue, $itrIdValue, '$userIdEscaped', $paymentIdValue, $panNumberValue, '$statusStepEscaped', $isCompletedInt, $completedAtValue, $notesEscaped, NOW(), NOW())";
            
            return $conn->query($insertSql);
        }
    }
    
    /**
     * Get status steps for an order/ITR
     * 
     * Behaviour:
     * - If both orderId and itrId are provided, return rows that belong to EITHER
     *   that order OR that itr (for the same user if userId is provided).
     * - If only one of them is provided, filter by that key (and userId if given).
     * - If none is provided but userId is, return all rows for that user.
     */
    public static function getStatusSteps($conn, $orderId = null, $itrId = null, $userId = null) {
        $conditions = [];

        // When userId is provided we always scope rows to that user
        $userCondition = null;
        if ($userId) {
            $userIdEscaped = mysqli_real_escape_string($conn, (string)$userId);
            $userCondition = "user_id = '$userIdEscaped'";
        }

        if ($orderId) {
            $orderIdEscaped = mysqli_real_escape_string($conn, $orderId);
            $cond = "order_id = '$orderIdEscaped'";
            if ($userCondition) {
                $cond .= " AND $userCondition";
            }
            $conditions[] = "($cond)";
        }

        if ($itrId) {
            $itrIdEscaped = (int)$itrId;
            $cond = "itr_id = $itrIdEscaped";
            if ($userCondition) {
                $cond .= " AND $userCondition";
            }
            $conditions[] = "($cond)";
        }

        // If neither orderId nor itrId is provided but userId is, fall back to all rows for that user
        if (!$orderId && !$itrId && $userCondition) {
            $conditions[] = "($userCondition)";
        }

        // If we still have no conditions, force empty result
        if (empty($conditions)) {
            return [];
        }

        $whereClause = implode(' OR ', $conditions);

        $sql = "SELECT * FROM itr_order_status WHERE $whereClause ORDER BY 
                FIELD(status_step, 'payment_success', 'expert_assigned', 'documents_verified', 'filing_itr', 'acknowledgement_generated')";
        
        $result = $conn->query($sql);
        $steps = [];
        
        if ($result && $result->num_rows > 0) {
            while ($row = $result->fetch_assoc()) {
                $steps[] = $row;
            }
        }
        
        return $steps;
    }
    
    /**
     * Get pending concern for a status step
     */
    public static function getPendingConcern($conn, $statusId) {
        $statusIdEscaped = (int)$statusId;
        $sql = "SELECT * FROM itr_order_concerns WHERE status_id = $statusIdEscaped AND status = 'pending' ORDER BY created_at DESC LIMIT 1";
        $result = $conn->query($sql);
        
        if ($result && $result->num_rows > 0) {
            return $result->fetch_assoc();
        }
        
        return null;
    }
    
    /**
     * Get latest concern for a status step (pending or resolved) – for display on step
     */
    public static function getLatestConcernForStatusIds($conn, array $statusIds) {
        if (empty($statusIds)) {
            return null;
        }
        $ids = array_map('intval', $statusIds);
        $ids = array_filter($ids);
        if (empty($ids)) {
            return null;
        }
        $idList = implode(',', $ids);
        $sql = "SELECT * FROM itr_order_concerns WHERE status_id IN ($idList) ORDER BY created_at DESC LIMIT 1";
        $result = $conn->query($sql);
        if ($result && $result->num_rows > 0) {
            return $result->fetch_assoc();
        }
        return null;
    }
    
    /**
     * Calculate overall status
     */
    public static function calculateOverallStatus($steps) {
        if (empty($steps)) {
            return 'pending';
        }
        
        $allCompleted = true;
        $hasPendingConcern = false;
        $anyInProgress = false;
        
        foreach ($steps as $step) {
            if (!$step['is_completed']) {
                $allCompleted = false;
                $anyInProgress = true;
            }
            
            if ($step['has_concern']) {
                $hasPendingConcern = true;
            }
        }
        
        if ($allCompleted) {
            return 'completed';
        } elseif ($hasPendingConcern) {
            return 'concern_pending';
        } elseif ($anyInProgress) {
            return 'in_progress';
        }
        
        return 'pending';
    }
    
    /**
     * Get current step number (last completed step)
     */
    public static function getCurrentStep($steps) {
        $maxOrder = 0;
        foreach ($steps as $step) {
            if ($step['is_completed']) {
                $order = self::getStepOrder($step['status_step']);
                if ($order > $maxOrder) {
                    $maxOrder = $order;
                }
            }
        }
        return $maxOrder;
    }
    
    /**
     * Get status step color for UI
     */
    public static function getStepColor($step) {
        $colors = [
            'payment_success' => '#28a745',         // Green
            'expert_assigned' => '#17a2b8',         // Cyan
            'documents_verified' => '#ffc107',      // Yellow
            'filing_itr' => '#fd7e14',              // Orange
            'acknowledgement_generated' => '#6f42c1' // Purple
        ];
        return $colors[$step] ?? '#6c757d';
    }
    
    /**
     * Get status step icon for UI
     */
    public static function getStepIcon($step) {
        $icons = [
            'payment_success' => 'check-circle',
            'expert_assigned' => 'user-check',
            'documents_verified' => 'file-check',
            'filing_itr' => 'upload',
            'acknowledgement_generated' => 'award'
        ];
        return $icons[$step] ?? 'circle';
    }
    
    /**
     * Admin dashboard display status (mobile workflow + explicit Paid before processing).
     *
     * @param bool $hasPaymentSuccess
     * @param string|null $ackNumber
     * @param array $statusSteps
     * @param bool $hasActiveAssignment
     * @return array{displayStatus:string,displayText:string,itrStatus:string,hasSuccessfulPayment:bool}
     */
    public static function resolveAdminDisplayStatus($hasPaymentSuccess, $ackNumber, $statusSteps, $hasActiveAssignment = false) {
        $ackNumber = is_string($ackNumber) ? trim($ackNumber) : '';

        if ($ackNumber !== '') {
            return [
                'displayStatus' => 'COMPLETED',
                'displayText' => 'Completed',
                'itrStatus' => 'completed',
                'hasSuccessfulPayment' => (bool) $hasPaymentSuccess,
            ];
        }

        if (!$hasPaymentSuccess) {
            return [
                'displayStatus' => 'PENDING',
                'displayText' => 'Pending',
                'itrStatus' => 'pending_payment',
                'hasSuccessfulPayment' => false,
            ];
        }

        foreach ($statusSteps as $step) {
            $code = $step['statusStep'] ?? $step['status_step'] ?? '';
            $done = !empty($step['isCompleted']) || !empty($step['is_completed']);
            if ($code === 'acknowledgement_generated' && $done) {
                $notes = trim($step['notes'] ?? '');
                if ($notes !== '') {
                    return [
                        'displayStatus' => 'COMPLETED',
                        'displayText' => 'Completed',
                        'itrStatus' => 'completed',
                        'hasSuccessfulPayment' => true,
                    ];
                }
            }
        }

        $normalized = [];
        foreach ($statusSteps as $step) {
            $normalized[] = [
                'is_completed' => !empty($step['isCompleted']) || !empty($step['is_completed']),
                'has_concern' => !empty($step['hasConcern']) || !empty($step['has_concern']),
                'status_step' => $step['statusStep'] ?? $step['status_step'] ?? '',
            ];
        }

        $overall = self::calculateOverallStatus($normalized);
        if ($overall === 'completed') {
            return [
                'displayStatus' => 'COMPLETED',
                'displayText' => 'Completed',
                'itrStatus' => 'completed',
                'hasSuccessfulPayment' => true,
            ];
        }

        $workflowStarted = (bool) $hasActiveAssignment;
        if (!$workflowStarted) {
            foreach ($normalized as $step) {
                if (!empty($step['has_concern'])) {
                    $workflowStarted = true;
                    break;
                }
                $code = $step['status_step'];
                if ($code === 'payment_success' || $code === '') {
                    continue;
                }
                if (!empty($step['is_completed'])) {
                    $workflowStarted = true;
                    break;
                }
            }
        }

        if (!$workflowStarted) {
            return [
                'displayStatus' => 'PAID',
                'displayText' => 'Paid',
                'itrStatus' => 'paid',
                'hasSuccessfulPayment' => true,
            ];
        }

        return [
            'displayStatus' => 'IN_PROGRESS',
            'displayText' => 'In Progress',
            'itrStatus' => $overall === 'concern_pending' ? 'concern_pending' : 'in_progress',
            'hasSuccessfulPayment' => true,
        ];
    }

    /**
     * Get overall status display text
     */
    public static function getOverallStatusText($status) {
        $texts = [
            'pending' => 'Pending',
            'in_progress' => 'In Progress',
            'concern_pending' => 'Action Required',
            'completed' => 'Completed'
        ];
        return $texts[$status] ?? $status;
    }
    
    /**
     * Get payment status display text
     */
    public static function getPaymentStatusText($status) {
        $texts = [
            'pending' => 'Pending',
            'success' => 'Success',
            'failed' => 'Failed',
            'cancelled' => 'Cancelled'
        ];
        return $texts[$status] ?? $status;
    }
    
    /**
     * Get assignment status display text
     */
    public static function getAssignmentStatusText($status) {
        $texts = [
            'assigned' => 'Assigned',
            'in_progress' => 'In Progress',
            'completed' => 'Completed',
            'rejected' => 'Rejected'
        ];
        return $texts[$status] ?? $status;
    }
}

