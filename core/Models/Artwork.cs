using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace ArtTimeTracker.Core.Models;

public class Artwork
{
    [Key]
    public int Id { get; set; }

    [Required]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(1000)]
    public string? Description { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.Now;

    public bool IsArchived { get; set; }

    /// <summary>
    /// Der .clip-Dateiname (ohne Extension) der Auto-Tracking auslöst.
    /// Null = kein Auto-Tracking, nur manuelles Tracking.
    /// </summary>
    [MaxLength(500)]
    public string? LinkedFileName { get; set; }

    public List<TrackingSession> Sessions { get; set; } = new();
}
