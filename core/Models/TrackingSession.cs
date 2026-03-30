using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ArtTimeTracker.Core.Models;

public class TrackingSession
{
    [Key]
    public int Id { get; set; }

    public int ArtworkId { get; set; }

    [ForeignKey(nameof(ArtworkId))]
    public Artwork Artwork { get; set; } = null!;

    public DateTime StartTime { get; set; }

    public DateTime EndTime { get; set; }

    [NotMapped]
    public TimeSpan Duration => EndTime - StartTime;
}
